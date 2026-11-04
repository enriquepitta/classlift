import * as XLSX from 'npm:xlsx@0.18.5';
import { careerCodes, parseWorkbook } from './parser.mjs';
import { sourceFor } from './source.mjs';

const universityPage = 'https://www.pol.una.py/academico/horarios-de-clases-y-examenes/';
const base = Deno.env.get('SUPABASE_URL')!;
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const headers = { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, 'Content-Type': 'application/json' };

async function jsonResponse(url: string, options: RequestInit = {}) {
  const response = await fetch(url, { ...options, signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`La fuente respondió con estado ${response.status}`);
  return response.json();
}

async function workbookBytes(fileId: string) {
  if (!/^[\w-]{10,100}$/.test(fileId)) throw new Error('Identificador de archivo inválido');
  const download = await fetch(`https://drive.google.com/uc?export=download&id=${encodeURIComponent(fileId)}`,
    { signal: AbortSignal.timeout(60000) });
  if (!download.ok) throw new Error(`No se pudo descargar la planilla (${download.status})`);
  const bytes = new Uint8Array(await download.arrayBuffer());
  if (bytes.length > 10_000_000 || bytes.length < 4 || bytes[0] !== 0x50 || bytes[1] !== 0x4b) {
    throw new Error('El archivo descargado no es un Excel válido o excede el tamaño permitido');
  }
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)))
    .map((byte) => byte.toString(16).padStart(2, '0')).join('');
  return { bytes, hash };
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  try {
    const token = req.headers.get('x-sync-secret') ?? '';
    if (!token || token.length > 200) return new Response('Unauthorized', { status: 401 });
    const authorized = await jsonResponse(`${base}/rest/v1/rpc/verify_faculty_sync_token`, {
      method: 'POST', headers, body: JSON.stringify({ input_token: token }),
    });
    if (authorized !== true) return new Response('Unauthorized', { status: 401 });
    const body = await req.json();
    if (body.career) {
      if (!careerCodes.has(body.career) || !/^[a-f0-9]{64}$/.test(body.hash ?? '')) {
        return new Response('Invalid request', { status: 400 });
      }
      const workbook = await workbookBytes(body.fileId ?? '');
      if (workbook.hash !== body.hash) throw new Error('La planilla cambió durante la importación');
      return Response.json(parseWorkbook(XLSX, workbook.bytes, body.career));
    }
    if (body.plan !== 'new' && body.plan !== 'previous') return new Response('Invalid plan', { status: 400 });

    const page = await fetch(universityPage, { signal: AbortSignal.timeout(30000) });
    if (!page.ok) throw new Error(`La página de la facultad respondió ${page.status}`);
    const source = sourceFor(await page.text(), body.plan);
    const { bytes, hash } = await workbookBytes(source.fileId);
    const existing = await jsonResponse(`${base}/rest/v1/faculty_schedule_catalogs?id=eq.${encodeURIComponent(source.id)}&select=source_hash,careers,total,scheduled`, { headers });
    if (existing[0]?.source_hash === hash) return Response.json({ status: 'unchanged', id: source.id });

    let result;
    if (bytes.length < 1_000_000) {
      result = parseWorkbook(XLSX, bytes);
    } else {
      // Large workbooks exceed the Edge CPU limit if all sheets are parsed in
      // one request. Parse one career per request, then publish atomically.
      result = { careers: {}, total: 0, scheduled: 0 };
      const names = [...careerCodes];
      for (let i = 0; i < names.length; i += 3) {
        const batch = await Promise.all(names.slice(i, i + 3).map((career) =>
          jsonResponse(`${base}/functions/v1/sync-faculty-schedules`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: req.headers.get('Authorization') ?? '', 'x-sync-secret': token },
            body: JSON.stringify({ career, fileId: source.fileId, hash }),
          })));
        for (const item of batch) {
          Object.assign(result.careers, item.careers);
          result.total += item.total;
          result.scheduled += item.scheduled;
        }
      }
      if (!Object.keys(result.careers).length || result.total < 10 || result.scheduled < 5) {
        throw new Error('La planilla no contiene suficientes horarios válidos');
      }
    }
    if (existing[0]) {
      const oldCareers = Object.keys(existing[0].careers);
      if (oldCareers.some((career) => !result.careers[career]) ||
          result.total < existing[0].total * 0.5 || result.scheduled < existing[0].scheduled * 0.5) {
        throw new Error('La planilla nueva parece incompleta; se conserva la versión anterior');
      }
    }
    const payload = { id: source.id, period: source.period, year: source.year, term: source.term,
      plan: source.plan, source_url: source.sourceUrl, source_hash: hash,
      careers: result.careers, total: result.total, scheduled: result.scheduled, updated_at: new Date().toISOString() };
    const saved = await fetch(`${base}/rest/v1/faculty_schedule_catalogs?on_conflict=id`, {
      method: 'POST', headers: { ...headers, Prefer: 'resolution=merge-duplicates,return=minimal' },
      body: JSON.stringify(payload), signal: AbortSignal.timeout(30000),
    });
    if (!saved.ok) throw new Error(`No se pudo publicar el catálogo (${saved.status})`);
    return Response.json({ status: 'updated', id: source.id, total: result.total, scheduled: result.scheduled });
  } catch (error) {
    console.error('Sincronización de horarios fallida:', error instanceof Error ? error.message : error);
    return Response.json({ error: 'No se pudo sincronizar el catálogo' }, { status: 500 });
  }
});
