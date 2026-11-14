const fs = require('fs');
const lines = fs.readFileSync(__dirname + '/equations.txt', 'utf8').split('\n');
const eqs = []; let comment = '';
for (const l of lines) { if (l.startsWith('#')) comment = l.slice(2); else if (/^\w+ = /.test(l)) { const i = l.indexOf(' = '); eqs.push({ name: l.slice(0, i), expr: l.slice(i + 3), comment }); comment = ''; } }
exports.eqs = eqs; exports.names = eqs.map(e => e.name);
exports.js = () => 'const {exp, log} = Math;\n' + eqs.map(e => `v.${e.name} = ${e.expr.replace(/Lp\./g, 'LP.')};`).join('\n') + '\nreturn v;';
exports.elm = () => { const done = new Set(); const out = [];
  for (const e of eqs) { let x = e.expr.replace(/Lp\.(\w+)/g, 'laggedParams.$1').replace(/L\.(\w+)/g, 'lagged.$1').replace(/p\.(\w+)/g, (m, n, off, s) => (s[off-1] && /\w/.test(s[off-1])) ? m : 'params.' + n)
      .replace(/v\.(\w+)/g, (m, n) => done.has(n) ? n : 'guess.' + n).replace(/exp\(/g, 'exp (').replace(/log\(/g, 'ln (');
    out.push({ name: e.name, expr: x, comment: e.comment }); done.add(e.name); }
  return out; };
