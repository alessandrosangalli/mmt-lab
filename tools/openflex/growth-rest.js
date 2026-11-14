const g = require('./growth.js'), m = require('./model.js'), c = require('./calibrate.js');
const start = { ...JSON.parse(require('fs').readFileSync(__dirname + '/steady.json')), tr_uk: 0 };
const f = (x, d = 3) => x.toFixed(d);
function rest(over, free, targets, from = start) {
  const base = { ...m.P0, ...c.port(2), eps1: .01, mu1: .55, g_k_uk: 18, r_uk: .035, r_us: .01, trend: 1, infl_uk: 1, infl_us: 1, tr_k_uk: 0, ...over };
  base.dxre_us = base.infl_uk / base.infl_us - 1; base.dxre_uk = base.infl_us / base.infl_uk - 1;
  // calibrate.rest works on m.KEYS; give it the growth system's keys
  const saved = [...m.KEYS]; m.KEYS.length = 0; m.KEYS.push(...g.KEYS);
  const r = c.rest(base, from, free, targets, g.sweep, base.trend * base.infl_uk === 1); m.KEYS.length = 0; m.KEYS.push(...saved); return r; }
const T = { im: v => v.im_uk / v.y_uk - .175, debt: v => v.b_uk_s / v.y_uk - 3.28, foreign: v => v.b_usuk_s / v.b_uk_s - .099, xr: v => v.xr_uk - 1,
  gov: v => v.g_uk / v.y_uk - .188, tax: v => v.t_uk / v.y_uk - .324 };
const show = (label, r) => { const v = r.v, p = r.p; console.log(label.padEnd(30), r.ok ? 'ok ' : 'NO ' + r.err.toExponential(1), `y ${f(v.y_k_uk, 1)} tax/y ${f(v.t_uk / v.y_uk)} gov/y ${f(v.g_uk / v.y_uk)} transfers/y ${f(v.tr_uk / v.y_uk)} deficit/y ${f(v.psbr_uk / v.y_uk)} interest/y ${f(p.r_uk * v.b_uk_s / p.trend / p.infl_uk / v.y_uk)} cons/y ${f(v.cons_uk / v.y_uk)} x/y ${f(v.x_uk / v.y_uk)} cab/y ${f(v.cab_uk / v.y_uk)} | theta ${f(p.theta_uk)} alpha2 ${f(p.alpha2_uk)} tr ${f(p.tr_k_uk, 2)} g ${f(p.g_k_uk, 2)}`); return r; };
const free4 = ['mu0', 'alpha2_uk', 'lambda50', 'eps0'], t4 = [T.im, T.debt, T.foreign, T.xr];
show('no growth (brazil-1)', rest({ theta_uk: .27 }, free4, t4));
const q = a => Math.pow(1 + a, .25);
const growthBR = { trend: q(.023), infl_uk: q(.045), infl_us: q(.027) };
show('growth, tax rate 27%', rest({ theta_uk: .27, ...growthBR }, free4, t4));
const full = show('growth + transfers, all targets', rest({ ...growthBR }, [...free4, 'theta_uk', 'tr_k_uk', 'g_k_uk'], [...t4, T.gov, T.tax, v => v.y_k_uk / 94.8344 - 1]));
show('same, no inflation', rest({ trend: q(.023) }, [...free4, 'theta_uk', 'tr_k_uk', 'g_k_uk'], [...t4, T.gov, T.tax, v => v.y_k_uk / 94.8344 - 1]));
if (full.ok) { for (const [name, set] of [['nothing', {}], ['g +5%', { g_k_uk: full.p.g_k_uk * 1.05 }], ['transfers +10%', { tr_k_uk: full.p.tr_k_uk * 1.1 }], ['r +0.5pp', { r_uk: .04 }]]) {
  const r = g.run(120, [{ at: 1, set }], full.v, full.p); const o = r.out; const at = i => o[i - 1] ? `t${i} xr ${f(o[i - 1].xr_uk)} y ${f(o[i - 1].y_k_uk, 1)} debt/y ${f(o[i - 1].b_uk_s / o[i - 1].y_uk, 2)} cab/y ${f(o[i - 1].cab_uk / o[i - 1].y_uk * 100, 2)}%` : '';
  console.log('  ', name.padEnd(16), r.failedAt ? 'FAIL@' + r.failedAt : 'ok', at(1), '|', at(40), '|', at(120)); } }
console.log('--- policy on round values: g 18, tax rate chosen; transfers solved. Continuation from the previous point.');
let prev = full;
for (const th of [.30, .31, .32, .33, .34, .35, .36, .37, .38, .39, .40]) { const r = rest({ ...prev.p, theta_uk: th, g_k_uk: 18, r_us: .0096 }, [...free4, 'tr_k_uk'], [...t4, T.gov], prev.v); show('theta ' + th, r); if (r.ok) prev = r; }
