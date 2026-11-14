// Prototype: the same equations on a growth path, with government transfers.
//
// Every quantity is measured relative to its trend. Real quantities grow at `growth` a period, prices at
// each country's `inflation`, money amounts at both. Relative to this period's trend, last period's value
// is smaller by one period of growth, so every lagged value is divided by its trend's growth factor.
// A point of rest of this system is a balanced growth path: debt grows with the economy, and the
// government runs the deficit that keeps debt constant as a share of output.
const gen = require('./gen.js'); const m = require('./model.js');
const usMoney = new Set(['b_usuk_d', 'b_usus_d', 'b_cb_usus_d', 'b_us_s', 'b_ukus_s', 'h_us_d']);
const kind = name => /^xr_/.test(name) ? 'xr' : /^p[a-z]+_/.test(name) && !/^psbr/.test(name) ? 'price' : /_k_|^n_/.test(name) ? 'real' : 'money';
const country = name => (/_us$/.test(name) || usMoney.has(name)) ? 'us' : 'uk';
function factor(name) { const c = country(name);
  switch (kind(name)) { case 'real': return 'p.trend'; case 'price': return `p.infl_${c}`; case 'money': return `(p.trend * p.infl_${c})`;
    case 'xr': return name === 'xr_uk' ? '(p.infl_us / p.infl_uk)' : '(p.infl_uk / p.infl_us)'; } }
const edits = { // transfers to households, in real terms
  yd_uk: e => e + ' + v.tr_uk', b_uk_s: e => e + ' + v.tr_uk', psbr_uk: e => e + ' + v.tr_uk' };
const eqs = []; for (const e of gen.eqs) { if (e.name === 'yd_uk') eqs.push({ name: 'tr_uk', expr: 'p.tr_k_uk * L.pds_uk' }); eqs.push({ name: e.name, expr: (edits[e.name] || (x => x))(e.expr) }); }
// transfers are set at last period's prices so that the ordering of the equations is kept
const lagged = e => e.replace(/\bLp\.b_cb_ukus_s\b/g, '(LP.b_cb_ukus_s / (p.trend * p.infl_us))').replace(/\bLp\./g, 'LP.').replace(/\bL\.(\w+)/g, (_, n) => `(L.${n} / ${factor(n)})`);
const KEYS = eqs.map(e => e.name);
const sweep = new Function('v', 'L', 'p', 'LP', 'const {exp, log} = Math;\n' + eqs.map(e => `v.${e.name} = ${lagged(e.expr)};`).join('\n') + '\nreturn v;');
function solve(L, p, LP) { let v = { ...L };
  for (let it = 1; it <= 2000; it++) { const before = KEYS.map(k => v[k]); sweep(v, L, p, LP);
    const err = Math.max(...KEYS.map((k, i) => Math.abs(v[k] - before[i]) / Math.max(1, Math.abs(before[i]))));
    if (!isFinite(err)) return null; if (err < 1e-12) return v; } return null; }
function run(n, shocks, start, base) { let p = { ...base }, LP = p, L = start; const out = [];
  for (let t = 1; t <= n; t++) { for (const s of shocks) if (t === s.at) p = { ...p, ...s.set }; const v = solve(L, p, LP); if (!v) return { out, failedAt: t }; out.push(v); L = v; LP = p; } return { out }; }
module.exports = { sweep, KEYS, run, eqs, lagged, factor };
