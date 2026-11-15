const fs = require('fs');
const lines = fs.readFileSync(__dirname + '/equations.txt', 'utf8').split('\n');
const eqs = []; let comment = '';
for (const l of lines) { if (l.startsWith('#')) comment = l.slice(2); else if (/^\w+ = /.test(l)) { const i = l.indexOf(' = '); eqs.push({ name: l.slice(0, i), expr: l.slice(i + 3), comment }); comment = ''; } }
exports.eqs = eqs; exports.names = eqs.map(e => e.name);
exports.js = () => 'const {exp, log} = Math;\n' + eqs.map(e => `v.${e.name} = ${e.expr.replace(/Lp\./g, 'LP.')};`).join('\n') + '\nreturn v;';
exports.elm = () => { const done = new Set(); const out = [];
  for (const e of eqs) { let x = e.expr.replace(/Lp\.(\w+)/g, 'laggedParams.$1').replace(/L\.(\w+)/g, 'lagged.$1').replace(/p\.(\w+)/g, (m, n, off, s) => (s[off-1] && /\w/.test(s[off-1])) ? m : 'params.' + n)
      .replace(/v\.(\w+)/g, (m, n) => done.has(n) ? n : 'guess.' + n).replace(/exp\(/g, 'exp (').replace(/log\(/g, 'ln (').replace(/\bln \(((?:guess|lagged|params)\.\w+|\w+)\)/g, 'ln $1');
    out.push({ name: e.name, expr: x, comment: e.comment }); done.add(e.name); }
  return out; };

// Trends. Real quantities grow at `trend` a period, each country's prices at its `infl`, money amounts at
// both, and an exchange rate at the ratio of the two inflations. Relative to this period's trend, last
// period's value is smaller by one period of growth: `carry` divides each lagged value by that growth.
const usMoney = new Set(['b_usuk_d', 'b_usus_d', 'b_cb_usus_d', 'b_us_s', 'b_ukus_s', 'h_us_d']);
const kind = name => /^(u|gpi)_/.test(name) ? 'rate' : /^xr_/.test(name) ? 'xr' : (/^p[a-z]+_/.test(name) && !/^psbr/.test(name)) || /^wage_/.test(name) ? 'price' : /_k_|^n_/.test(name) ? 'real' : 'money';
const country = name => (/_us$/.test(name) || usMoney.has(name)) ? 'us' : 'uk';
exports.factor = (name, p = 'p') => { const c = country(name);
  switch (kind(name)) { case 'rate': return '1'; case 'real': return `${p}.trend`; case 'price': return `${p}.infl_${c}`; case 'money': return `(${p}.trend * ${p}.infl_${c})`;
    default: return name === 'xr_uk' ? `(${p}.infl_us / ${p}.infl_uk)` : `(${p}.infl_uk / ${p}.infl_us)`; } };
exports.carryJs = () => 'return {' + exports.names.map(n => `${n}: L.${n} / ${exports.factor(n)}`).join(', ') + '};';
