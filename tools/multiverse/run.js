// Runs the multiverse (src/Batch.elm, compiled) and writes its results.
// Usage: node tools/multiverse/run.js <compiled batch.js> <output directory>
const fs = require('fs'); const path = require('path');
const [compiled, outDir] = process.argv.slice(2);
if (!compiled || !outDir) { console.error('usage: run.js <batch.js> <output directory>'); process.exit(2); }
const started = Date.now();
const { Elm } = require(path.resolve(compiled));
const app = Elm.Batch.init();
app.ports.report.subscribe(data => {
  const seconds = ((Date.now() - started) / 1000).toFixed(1);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'multiverse.json'), JSON.stringify(data));
  fs.writeFileSync(path.join(outDir, 'multiverse.html'), page(data));
  const total = data.changes.reduce((n, c) => n + c.runs.length, 0);
  console.log(`multiverse: ${total} runs of ${data.model} in ${seconds}s`);
  for (const c of data.changes) console.log('  ' + c.name.padEnd(40), JSON.stringify(tally(c.runs)));
});

const tally = runs => { const t = { settles: 0, slowing: 0, speeding: 0, failed: 0 }; for (const r of runs) t[r.outcome]++; return t; };
const number = (x, places = 2) => x.toFixed(places).replace('.', ',');
const median = xs => { const s = [...xs].sort((a, b) => a - b); return s.length ? (s[(s.length - 1) >> 1] + s[s.length >> 1]) / 2 : NaN; };
const range = xs => xs.length ? `${number(Math.min(...xs))} a ${number(Math.max(...xs))}, mediana ${number(median(xs))}` : 'nenhum';
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');

function page(data) {
  const sections = data.changes.map(change => {
    const t = tally(change.runs), solved = change.runs.filter(r => r.outcome !== 'failed');
    const byPremise = data.premises.map(premise => {
      const rows = premise.values.map(value => { const these = change.runs.filter(r => r.premises[premise.key] === value), c = tally(these);
        const rates = these.filter(r => r.outcome !== 'failed').map(r => r.rate);
        return `<tr><th scope="row">${number(value, 3)}</th><td>${c.settles}</td><td>${c.slowing}</td><td>${c.speeding}</td><td>${c.failed}</td><td>${rates.length ? number(median(rates)) : 'sem solução'}</td></tr>`; }).join('');
      return `<h3>${esc(premise.name)}</h3><div class="scroll"><table><thead><tr><th>Valor</th><th>Estabiliza</th><th>Desacelera</th><th>Acelera</th><th>Sem solução</th><th>Câmbio final, mediana</th></tr></thead><tbody>${rows}</tbody></table></div>`; }).join('');
    return `<section><h2>${esc(change.name)}</h2>
<p>De ${change.runs.length} combinações de premissas: <strong>${t.settles}</strong> estabilizam; <strong>${t.slowing}</strong> ainda se ajustam, mas cada vez mais devagar; <strong>${t.speeding}</strong> se afastam cada vez mais rápido; e <strong>${t.failed}</strong> ficam sem solução antes do fim.</p>
<p>Entre as que chegam ao fim, o câmbio em relação à tendência termina de ${range(solved.map(r => r.rate))}, e a dívida pública de ${range(solved.map(r => r.debt))} vezes o PIB trimestral (parte de 3,28).</p>
${byPremise}</section>`; }).join('\n');
  const grid = data.premises.map(p => `${esc(p.name)}: ${p.values.map(v => number(v, 3)).join('; ')}`).join('</li><li>');
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Multiverso do Laboratório MMT</title>
<style>:root{--ground:#eef2ee;--sheet:#f8faf7;--ink:#16242a;--muted:#5a6a6b;--rule:#cfd9d3;--blue:#1f5fa6}
@media (prefers-color-scheme:dark){:root{--ground:#0f1719;--sheet:#162225;--ink:#e2eae5;--muted:#95a6a4;--rule:#2b3c3f;--blue:#74aae6;color-scheme:dark}}
body{margin:0;background:var(--ground);color:var(--ink);font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;line-height:1.55}
main{max-width:860px;margin:0 auto;padding:24px 16px 48px}h1{font-family:Georgia,serif;font-size:1.8rem;margin:0 0 8px}h2{font-size:1.15rem;margin:32px 0 8px;padding-top:16px;border-top:1px solid var(--rule)}h3{font-size:.95rem;margin:18px 0 6px}
p,li{max-width:68ch}.muted{color:var(--muted)}a{color:var(--blue)}.scroll{overflow-x:auto}
table{border-collapse:collapse;background:var(--sheet);font-size:.9rem;min-width:420px;width:100%}th,td{padding:7px 10px;text-align:right;border-bottom:1px solid var(--rule);font-variant-numeric:tabular-nums}
thead th{font-size:.72rem;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);border-bottom:2px solid var(--ink)}th[scope=row],thead th:first-child{text-align:left;font-weight:500}</style></head><body><main>
<h1>Multiverso</h1>
<p>O modelo BRASIL (versão ${esc(data.model)}) rodado com todas as combinações das premissas dentro da faixa das estimativas brasileiras lidas, por ${data.horizon} trimestres, para cada mudança de política. Esta página é gerada a cada publicação do laboratório.</p>
<p class="muted">É uma descrição do modelo, não um veredito sobre o Brasil: os critérios das teses ainda não foram pré-registrados, e o modelo é uma calibração parcial. "Estabiliza" quer dizer que o câmbio se moveu menos de 1% nos últimos dez trimestres. "Desacelera" e "acelera" comparam o movimento do câmbio nos últimos dez trimestres com o dos dez anteriores: quem desacelera caminha para se acomodar, ainda que leve décadas; quem acelera, não.</p>
<p>Valores de cada premissa:</p><ul><li>${grid}</li></ul>
<p><a href="./">Voltar ao laboratório</a></p>
${sections}
</main></body></html>`; }
