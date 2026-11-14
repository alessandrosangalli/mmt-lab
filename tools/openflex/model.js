const gen = require('./gen.js');
const sweepFn = new Function('v', 'L', 'p', 'LP', gen.js());
const P0 = { alpha1_uk:.75, alpha1_us:.75, alpha2_uk:.13333, alpha2_us:.13333, eps0:-2.1, eps1:.7, eps2:1,
  lambda10:.7, lambda11:5, lambda12:5, lambda20:.25, lambda21:5, lambda22:5, lambda40:.7, lambda41:5, lambda42:5, lambda50:.25, lambda51:5, lambda52:5,
  mu0:-2.1, mu1:.7, mu2:1, nu0m:-0.00001, nu0x:-0.00001, nu1m:.7, nu1x:.5, phi_uk:.2381, phi_us:.2381, theta_uk:.2, theta_us:.2,
  dxre_us:0, dxre_uk:0, g_k_uk:16, g_k_us:16, pr_uk:1.3333, pr_us:1.3333, r_uk:.03, r_us:.03, w_uk:1, w_us:1, b_cb_ukus_s:0.02031 };
const BOOK = { b_ukuk_d:102.18, b_ukus_d:36.493, b_ukus_s:36.504, b_usuk_d:36.497, b_usuk_s:36.487, b_usus_d:102.19, h_uk_d:7.2987, h_us_d:7.2995,
  v_k_uk:152.62, v_k_us:152.63, v_uk:145.97, v_us:145.99001, c_k_uk:81.393, c_k_us:81.401, cons_uk:77.851, cons_us:77.86, im_k_uk:11.928, im_k_us:11.926, im_uk:11.407, im_us:11.409,
  n_uk:73.046, n_us:73.054, pds_uk:.95648, pds_us:.95649, pm_uk:.95628, pm_us:.95661, ps_uk:.95646, ps_us:.9565, px_uk:.95634, px_us:.95656, py_uk:.95648, py_us:.95649,
  s_k_uk:109.32, s_k_us:109.33, s_uk:104.56, s_us:104.57, t_uk:19.463, t_us:19.465, x_k_uk:11.926, x_k_us:11.928, x_uk:11.406, x_us:11.41, xr_uk:1.0003, xr_us:.99971,
  y_k_uk:97.392, y_k_us:97.403, y_uk:93.154, y_us:93.164, yd_uk:77.851, yd_us:77.86, ydhs_k_uk:81.394, ydhs_k_us:81.402, ydhse_k_uk:81.394, ydhse_k_us:81.402,
  g_uk:15.304, g_us:15.304, f_cb_uk:0, f_cb_us:0, cab_uk:0, psbr_uk:0, psbr_us:0 };
// A start with no gold whose stocks are exactly consistent: each central bank holds bills against the money it issued,
// and each government's debt is the sum of what its holders hold.
function consistentStart() { const s = { ...BOOK };
  s.b_cb_usus_d = s.h_us_d; s.b_cb_ukuk_d = s.h_uk_d - P0.b_cb_ukus_s * s.xr_us;
  s.b_uk_s = s.b_ukuk_d + s.b_cb_ukuk_d + s.b_usuk_s; s.b_us_s = s.b_usus_d + s.b_cb_usus_d + s.b_ukus_s + P0.b_cb_ukus_s; return s; }
const KEYS = gen.names;
function solve(L, p, LP, opts = {}) { let v = { ...L };
  for (let it = 1; it <= (opts.max ?? 500); it++) { const before = KEYS.map(k => v[k]); sweepFn(v, L, p, LP);
    const err = Math.max(...KEYS.map((k, i) => Math.abs(v[k] - before[i]) / Math.max(1, Math.abs(before[i]))));
    if (!isFinite(err)) return { ok: false, it, why: 'nan' }; if (err < (opts.tol ?? 1e-12)) return { ok: true, it, v }; }
  return { ok: false, it: -1, why: 'maxit' }; }
function run(n, shocks = [], start = null, base = {}) { let p = { ...P0, ...base }, LP = p, L = start || consistentStart(); const out = []; let maxIt = 0;
  for (let t = 1; t <= n; t++) { for (const s of shocks) if (t === s.at) p = { ...p, ...s.set };
    const r = solve(L, p, LP); if (!r.ok) return { out, maxIt, failedAt: t, why: r.why };
    maxIt = Math.max(maxIt, r.it); out.push({ t, ...r.v, _L: L, _p: p, _LP: LP }); L = r.v; LP = p; }
  return { out, maxIt }; }
// transactions matrix of the UK in pounds: columns H F G CB RoW; returns max abs column sum
function tfm(o) { const L = o._L, LP = o._LP, p = o._p; const col = { H: 0, F: 0, G: 0, CB: 0, R: 0 }; const flow = (from, to, a) => { col[from] -= a; col[to] += a; };
  flow('H','F',o.cons_uk); flow('G','F',o.g_uk); flow('R','F',o.x_uk); flow('F','R',o.im_uk); flow('F','H',o.y_uk); flow('H','G',o.t_uk);
  flow('G','H',LP.r_uk*L.b_ukuk_d); flow('G','CB',LP.r_uk*L.b_cb_ukuk_d); flow('G','R',LP.r_uk*L.b_usuk_s);
  flow('R','H',o.xr_us*LP.r_us*L.b_ukus_s); flow('R','CB',o.xr_us*LP.r_us*LP.b_cb_ukus_s); flow('CB','G',o.f_cb_uk);
  flow('H','CB',o.h_uk_d-L.h_uk_d); flow('H','G',o.b_ukuk_d-L.b_ukuk_d); flow('CB','G',o.b_cb_ukuk_d-L.b_cb_ukuk_d); flow('R','G',o.b_usuk_s-L.b_usuk_s);
  flow('H','R',(o.b_ukus_s-L.b_ukus_s)*o.xr_us); flow('CB','R',(p.b_cb_ukus_s-LP.b_cb_ukus_s)*o.xr_us);
  return col; }
module.exports = { run, P0, BOOK, consistentStart, tfm, KEYS };
if (require.main === module) {
  const f = (x, d = 4) => x.toFixed(d);
  // settle to the exact steady state
  const settle = run(600); const S = settle.out.at(-1); const prev = settle.out.at(-2);
  console.log('settled: maxIt', settle.maxIt, 'drift last step', Math.max(...KEYS.map(k => Math.abs(S[k] - prev[k]))).toExponential(1));
  const worst = Object.keys(BOOK).filter(k => BOOK[k] !== 0).map(k => [k, Math.abs(S[k] / BOOK[k] - 1)]).sort((a, b) => b[1] - a[1]).slice(0, 4);
  console.log('largest relative gaps vs the book steady state:', worst.map(([k, e]) => k + ' ' + e.toExponential(1)).join(', '));
  console.log('key values: y_k_uk', f(S.y_k_uk, 3), 'y_k_us', f(S.y_k_us, 3), 'xr_uk', f(S.xr_uk, 5), 'pds_uk', f(S.pds_uk, 5), 'v_uk', f(S.v_uk, 3), 'b_uk_s', f(S.b_uk_s, 3));
  const start = Object.fromEntries(KEYS.map(k => [k, S[k]]));
  const check = (label, shocks, base) => { const r = run(120, shocks, start, base); if (r.failedAt) { console.log(label, 'FAILED at', r.failedAt, r.why); return r; }
    let worstCol = 0, hidden = 0; for (const o of r.out) { const c = tfm(o); worstCol = Math.max(worstCol, ...Object.values(c).map(Math.abs)); hidden = Math.max(hidden, Math.abs((o.h_uk_d - o._L.h_uk_d) - (o.b_cb_ukuk_d - o._L.b_cb_ukuk_d) - (o._p.b_cb_ukus_s - o._LP.b_cb_ukus_s) * o.xr_us)); }
    const o = r.out.at(-1), a = r.out[19]; console.log(label, '| maxIt', r.maxIt, '| worst column', worstCol.toExponential(1), '| hidden', hidden.toExponential(1), '| t20 xr', f(a.xr_uk), 'y_k_uk', f(a.y_k_uk, 3), '| t120 xr', f(o.xr_uk), 'y_k_uk', f(o.y_k_uk, 3), 'cab', f(o.cab_uk, 3)); return r; };
  check('baseline', []);
  check('S1 exports fall (eps0 -2.2)', [{ at: 5, set: { eps0: -2.2 } }]);
  check('S2 US spending 18', [{ at: 5, set: { g_k_us: 18 } }]);
  check('S3 portfolio shift', [{ at: 5, set: { lambda20: .30, lambda40: .75 } }]);
  check('UK spending 20', [{ at: 5, set: { g_k_uk: 20 } }]);
  check('UK rate 6%', [{ at: 5, set: { r_uk: .06 } }]);
  check('UK rate 0%', [{ at: 5, set: { r_uk: 0 } }]);
  check('UK tax 30%', [{ at: 5, set: { theta_uk: .30 } }]);
  require('fs').writeFileSync(__dirname + '/steady.json', JSON.stringify(start, null, 1));
}
