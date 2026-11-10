import assert from 'node:assert/strict';
import { parseWorkbook } from '../supabase/functions/sync-faculty-schedules/parser.mjs';
import { sourceFor } from '../supabase/functions/sync-faculty-schedules/source.mjs';

const header = Array(43).fill('');
Object.assign(header, { 2: 'Asignatura', 4: 'Sem/Grupo', 8: 'Turno', 9: 'Sección',
  10: 'Tít', 11: 'Apellido', 12: 'Nombre', 14: 'Día', 15: 'Hora',
  16: 'Día', 17: 'Hora', 31: 'AULA', 32: 'Lunes' });
const groups = Array(43).fill('');
Object.assign(groups, { 14: 'Evaluación Primera Etapa', 16: 'Evaluación Segunda Etapa' });
const row = Array(43).fill('');
Object.assign(row, { 2: 'Álgebra', 4: 1, 8: 'M', 9: 'MA', 10: 'Lic.', 11: 'Ríos',
  12: 'Ana', 14: '07/09/2026', 15: '08:00', 16: '02/11/2026', 17: '08:00',
  31: 'A01', 32: '08:00 - 10:00' });
const rows = [groups, header, ...Array(10).fill(row)];
const xlsx = { read: () => ({ SheetNames: ['IIN'], Sheets: { IIN: rows } }),
  utils: { sheet_to_json: (sheet) => sheet } };
const parsed = parseWorkbook(xlsx, new Uint8Array());
const label = parsed.careers.IIN['1'][0];
assert.match(label, /Álgebra — Mañana — MA — Lic\. Ana Ríos — Lunes:08:00 - 10:00\|A01/);
const encoded = label.split(' — ').find((part) => part.startsWith('@eval='));
const evaluations = JSON.parse(Buffer.from(encoded.slice(6), 'base64url').toString('utf8'));
assert.deepEqual(evaluations.map((evaluation) => evaluation.date), ['2026-09-07', '2026-11-02']);
assert.throws(() => parseWorkbook({ ...xlsx, utils: { sheet_to_json: () => [[1]] } }, new Uint8Array()));

const html = `<h3>Segundo Período Académico 2026 – Carreras de Grado</h3>
<table><tr><td>Planes de estudios 2026 (nuevos)</td><td>Planes de estudios anteriores</td></tr>
<tr><td><a href="https://docs.google.com/spreadsheets/d/new-file-123/edit">Ver</a></td>
<td><a href="https://docs.google.com/spreadsheets/d/old-file-123/edit">Ver</a></td></tr></table>`;
assert.equal(sourceFor(html, 'new').fileId, 'new-file-123');
assert.equal(sourceFor(html, 'previous').fileId, 'old-file-123');
assert.throws(() => sourceFor('<h3>Sin horarios</h3>', 'new'));
console.log('Faculty schedule parser: OK');
