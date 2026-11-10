// Converts the faculty workbook into the labels consumed by ClassLift's
// existing selection and local persistence flows. It deliberately rejects
// unknown layouts rather than publishing a partial or misleading catalogue.
export const careerCodes = new Set([
  'TSE', 'LEL', 'LCA', 'LGH', 'LCI', 'IMK', 'IIN', 'IEK', 'IEL',
  'LCIk', 'ISP', 'ICM', 'IAE', 'IEN',
]);
const weekdays = new Map([
  ['lunes', 'Lunes'], ['martes', 'Martes'], ['miercoles', 'Miércoles'],
  ['jueves', 'Jueves'], ['viernes', 'Viernes'], ['sabado', 'Sábado'],
]);
const normalize = (value) => String(value ?? '').trim().toLowerCase()
  .normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]/g, '');
const value = (row, index) => index == null ? '' : String(row[index] ?? '').trim();

function encodePayload(payload) {
  const bytes = new TextEncoder().encode(JSON.stringify(payload));
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_');
}

function dateOf(input) {
  if (!input) return null;
  const numeric = Number(input.replace(',', '.'));
  if (Number.isFinite(numeric) && numeric >= 1 && numeric < 100000) {
    return new Date(Date.UTC(1899, 11, 30) + Math.floor(numeric) * 86400000)
      .toISOString().slice(0, 10);
  }
  const match = input.match(/(\d{1,2})\/(\d{1,2})\/(\d{2,4})/);
  if (!match) return /^\d{4}-\d{2}-\d{2}$/.test(input) ? input : null;
  const year = Number(match[3]) < 100 ? 2000 + Number(match[3]) : Number(match[3]);
  return `${year}-${match[2].padStart(2, '0')}-${match[1].padStart(2, '0')}`;
}

function timeOf(input) {
  if (!input) return null;
  const numeric = Number(input.replace(',', '.'));
  if (Number.isFinite(numeric) && numeric >= 0 && numeric < 1) {
    const mins = Math.round(numeric * 1440) % 1440;
    return `${String(Math.floor(mins / 60)).padStart(2, '0')}:${String(mins % 60).padStart(2, '0')}`;
  }
  const match = input.match(/^(\d{1,2}):(\d{2})/);
  return match ? `${match[1].padStart(2, '0')}:${match[2]}` : null;
}

function validRange(input) {
  const m = input.match(/^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$/);
  if (!m) return false;
  const [h1, m1, h2, m2] = m.slice(1).map(Number);
  return h1 < 24 && h2 < 24 && m1 < 60 && m2 < 60 && h1 * 60 + m1 < h2 * 60 + m2;
}

function sheetLayout(rows, name) {
  const sample = rows.slice(0, 40);
  const header = sample.find((row) => {
    const values = new Set(row.map(normalize));
    return ['asignatura', 'materia', 'nombreasignatura'].some((v) => values.has(v)) &&
      ['semestre', 'semgrupo', 'semestregrupo', 'nivel', 'grupo'].some((v) => values.has(v));
  });
  if (!header) throw new Error(`No se reconoció el encabezado de ${name}`);
  const column = (...aliases) => {
    const i = header.findIndex((cell) => aliases.includes(normalize(cell)));
    return i < 0 ? null : i;
  };
  const subject = column('asignatura', 'materia', 'nombreasignatura');
  const semester = column('semestre', 'semgrupo', 'semestregrupo', 'grupo');
  if (subject == null || semester == null) throw new Error(`Faltan columnas esenciales en ${name}`);
  const days = [];
  for (let i = 0; i < header.length; i++) {
    const day = weekdays.get(normalize(header[i]));
    if (!day) continue;
    if (normalize(header[i - 1]) === 'aula') days.push([day, i - 1, i]);
    else if (normalize(header[i + 1]) === 'aula') days.push([day, i + 1, i]);
  }
  if (!days.length) throw new Error(`No se reconocieron los horarios en ${name}`);

  const evaluationColumns = new Map();
  let revision = 0;
  for (let r = 0; r + 1 < sample.length; r++) {
    const row = sample[r];
    for (let i = 0; i < row.length; i++) {
      const group = normalize(row[i]);
      let target = null;
      if (group.includes('parcial') || group.includes('etapa')) {
        target = group.includes('2') || group.includes('segunda') ? 18 : 15;
      } else if (group.includes('final') && !group.includes('derecho')) {
        target = group.startsWith('2') ? 26 : group.startsWith('1') ? 21 : null;
      } else if (group === 'revision') {
        target = revision++ === 0 ? 24 : 29;
      } else if (group === 'mesaexaminadora') {
        let member = 32;
        for (let c = i; c < i + 3; c++) {
          const sub = normalize(sample[r + 1][c]);
          if (sub === 'presidente') evaluationColumns.set(31, c);
          else if (sub === 'miembro' && member <= 33) evaluationColumns.set(member++, c);
        }
      }
      if (target == null) continue;
      const nextGroup = row.findIndex((cell, index) => {
        if (index <= i) return false;
        const next = normalize(cell);
        return next.includes('parcial') || next.includes('final') ||
          next === 'revision' || next.includes('evaluacionprimeraetapa') ||
          next.includes('evaluacionsegundaetapa');
      });
      const end = Math.min(i + 3, nextGroup < 0 ? i + 3 : nextGroup);
      for (let c = i; c < end; c++) {
        const sub = normalize(sample[r + 1][c]);
        if (['dia', 'fecha'].includes(sub)) evaluationColumns.set(target, c);
        if (['hora', 'horario'].includes(sub)) evaluationColumns.set(target + 1, c);
        if (sub === 'aula' && target !== 24 && target !== 29) evaluationColumns.set(target + 2, c);
      }
    }
  }
  return { subject, semester, shift: column('turno'), section: column('seccion'),
    title: column('tit', 'titulo', 'titulodocente'), last: column('apellido', 'apellidos'),
    first: column('nombre', 'nombres'), days, evaluationColumns };
}

function labelFor(row, layout) {
  const subject = value(row, layout.subject);
  const semester = Number(value(row, layout.semester).replace(',', '.'));
  if (!subject || !Number.isInteger(semester) || semester <= 0) return null;
  const shift = value(row, layout.shift);
  const parts = [subject, ({ M: 'Mañana', T: 'Tarde', N: 'Noche' })[shift.toUpperCase()] ?? shift];
  const section = value(row, layout.section);
  if (section) parts.push(section);
  const professor = [value(row, layout.title), value(row, layout.first).split(/\s+/)[0],
    value(row, layout.last).split(/\s+/)[0]].filter((part) => part && !part.includes('@')).join(' ');
  if (professor) parts.push(professor);
  const schedules = [];
  for (const [day, classroomColumn, timeColumn] of layout.days) {
    const classroom = value(row, classroomColumn), time = value(row, timeColumn);
    if (validRange(time) && classroom && !classroom.includes(':') && !classroom.includes('@')) {
      schedules.push(`${day}:${time}|${classroom}`);
    }
  }
  if (schedules.length) parts.push(schedules.join(';'));
  const board = [];
  for (const [index, role] of [[31, 'Presidente'], [32, 'Miembro'], [33, 'Miembro']]) {
    const name = value(row, layout.evaluationColumns.get(index));
    if (name) board.push({ name, role });
  }
  if (board.length) parts.push(`@mesa=${encodePayload(board)}`);
  const evaluations = [];
  for (const [type, dateCol, timeCol, roomCol] of [
    ['1.er Parcial', 15, 16, null], ['2.do Parcial', 18, 19, null],
    ['1.er Final', 21, 22, 23], ['Revisión', 24, 25, null],
    ['2.do Final', 26, 27, 28], ['Revisión final', 29, 30, null],
  ]) {
    const date = dateOf(value(row, layout.evaluationColumns.get(dateCol)));
    if (!date) continue;
    const time = timeOf(value(row, layout.evaluationColumns.get(timeCol)));
    const classroom = value(row, layout.evaluationColumns.get(roomCol));
    evaluations.push({ type, date, ...(time ? { time } : {}), ...(classroom ? { classroom } : {}) });
  }
  if (evaluations.length) parts.push(`@eval=${encodePayload(evaluations)}`);
  return { semester, label: parts.join(' — '), hasSchedule: schedules.length > 0 };
}

export function parseWorkbook(XLSX, bytes, onlyCareer = null) {
  const workbook = XLSX.read(bytes, { type: 'array', cellDates: false,
    ...(onlyCareer ? { sheets: [onlyCareer] } : {}) });
  const result = {};
  let total = 0, scheduled = 0;
  for (const name of workbook.SheetNames) {
    if (!careerCodes.has(name) || (onlyCareer && name !== onlyCareer)) continue;
    const rows = XLSX.utils.sheet_to_json(workbook.Sheets[name], { header: 1, raw: true, defval: '' });
    const layout = sheetLayout(rows, name);
    const semesters = {};
    for (const row of rows) {
      const item = labelFor(row, layout);
      if (!item) continue;
      (semesters[item.semester] ??= new Set()).add(item.label);
      total++;
      if (item.hasSchedule) scheduled++;
    }
    result[name] = Object.fromEntries(Object.entries(semesters).map(([k, labels]) => [k, [...labels].sort()]));
  }
  if (!onlyCareer && (!Object.keys(result).length || total < 10 || scheduled < 5)) {
    throw new Error('La planilla no contiene suficientes horarios válidos');
  }
  return { careers: result, total, scheduled };
}
