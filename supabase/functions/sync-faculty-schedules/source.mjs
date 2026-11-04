function plain(input) {
  return input.replace(/<[^>]*>/g, ' ').replace(/&nbsp;|&#160;/g, ' ')
    .replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();
}

export function sourceFor(html, requestedPlan) {
  const headings = [...html.matchAll(/<h[2-4]\b[^>]*>([\s\S]*?)<\/h[2-4]>/gi)];
  for (let i = 0; i < headings.length; i++) {
    const title = plain(headings[i][1]);
    const match = title.match(/(primer|segundo)\s+per[ií]odo\s+acad[eé]mico\s+(20\d{2})/i);
    if (!match) continue;
    const from = (headings[i].index ?? 0) + headings[i][0].length;
    const to = headings[i + 1]?.index ?? html.length;
    const table = html.slice(from, to).match(/<table\b[^>]*>([\s\S]*?)<\/table>/i)?.[1];
    if (!table) continue;
    const rows = [...table.matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)];
    if (rows.length < 2) continue;
    const labels = [...rows[0][1].matchAll(/<t[dh]\b[^>]*>([\s\S]*?)<\/t[dh]>/gi)].map((m) => plain(m[1]));
    const cells = [...rows[1][1].matchAll(/<t[dh]\b[^>]*>([\s\S]*?)<\/t[dh]>/gi)].map((m) => m[1]);
    if (labels.length < 2 || cells.length < 2 || !/planes? de estudios/i.test(labels.join(' '))) continue;
    const index = requestedPlan === 'new' ? 0 : 1;
    const href = cells[index]?.match(/href=["'](https:\/\/docs\.google\.com\/spreadsheets\/d\/([\w-]+)\/[^"']*)["']/i);
    if (!href) throw new Error('La facultad cambió el enlace de la planilla de horarios');
    const year = Number(match[2]);
    const term = match[1].toLowerCase() === 'primer' ? 1 : 2;
    return { id: `${year}-${term}-${requestedPlan}`, period: `${term === 1 ? 'Primer' : 'Segundo'} período ${year}`,
      year, term, plan: labels[index], fileId: href[2], sourceUrl: href[1].replaceAll('&amp;', '&') };
  }
  throw new Error('No se encontró un período académico con planes descargables');
}
