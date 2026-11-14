// Finds a resting point of the model directly, as a system of equations, instead of waiting for the
// economy to converge. Some parameters are left free and chosen so that the resting point reproduces
// target proportions (taxes, government consumption, imports, debt and foreign holdings over output).
const m = require('./model.js'); const gen = require('./gen.js');
const sweep = new Function('v', 'L', 'p', 'LP', gen.js());
const KEYS = m.KEYS;

function solveLinear(A, b) { const n = b.length; const M = A.map((r, i) => [...r, b[i]]);
  for (let c = 0; c < n; c++) { let best = c; for (let r = c + 1; r < n; r++) if (Math.abs(M[r][c]) > Math.abs(M[best][c])) best = r;
    [M[c], M[best]] = [M[best], M[c]]; const piv = M[c][c]; if (Math.abs(piv) < 1e-300) continue;
    for (let r = 0; r < n; r++) if (r !== c) { const f = M[r][c] / piv; if (f) for (let k = c; k <= n; k++) M[r][k] -= f * M[c][k]; } }
  return M.map((r, i) => Math.abs(r[i]) < 1e-300 ? 0 : r[n] / r[i]); }

// free: names of parameters to solve for. targets: functions (v, p) -> residual that must be zero.
function rest(params, start, free = [], targets = []) {
  const n = KEYS.length, N = n + free.length;
  const unpack = x => { const v = {}; KEYS.forEach((k, i) => v[k] = x[i]); const p = { ...params }; free.forEach((k, i) => p[k] = x[n + i]); return { v, p }; };
  const residual = x => { const { v, p } = unpack(x); const w = sweep({ ...v }, v, p, p);
    const r = KEYS.map(k => (w[k] - v[k]) / Math.max(1, Math.abs(v[k])));
    // each central bank holds bills against the money it issued (no accumulated revaluation gains)
    r.push((v.b_cb_usus_d - v.h_us_d) / 10, (v.b_cb_ukuk_d - (v.h_uk_d - p.b_cb_ukus_s * v.xr_us)) / 10);
    for (const t of targets) r.push(t(v, p)); return r; };
  let x = [...KEYS.map(k => start[k]), ...free.map(k => params[k])], lambda = 1e-3;
  const norm = r => Math.sqrt(r.reduce((s, e) => s + e * e, 0));
  let r = residual(x), err = norm(r);
  for (let it = 0; it < 400 && err > 1e-11; it++) {
    const J = r.map(() => new Array(N).fill(0));
    for (let j = 0; j < N; j++) { const h = 1e-7 * Math.max(1, Math.abs(x[j])); const y = [...x]; y[j] += h; const rj = residual(y); for (let i = 0; i < r.length; i++) J[i][j] = (rj[i] - r[i]) / h; }
    const JtJ = Array.from({ length: N }, (_, a) => Array.from({ length: N }, (_, b) => { let s = 0; for (let i = 0; i < r.length; i++) s += J[i][a] * J[i][b]; return s; }));
    const Jtr = Array.from({ length: N }, (_, a) => { let s = 0; for (let i = 0; i < r.length; i++) s += J[i][a] * r[i]; return -s; });
    let moved = false;
    for (let tries = 0; tries < 30; tries++) { const A = JtJ.map((row, a) => row.map((e, b) => a === b ? e * (1 + lambda) + lambda * 1e-12 : e));
      const dx = solveLinear(A, Jtr); const y = x.map((e, i) => e + dx[i]); const ry = residual(y), ey = norm(ry);
      if (isFinite(ey) && ey < err) { x = y; r = ry; err = ey; lambda = Math.max(lambda / 5, 1e-12); moved = true; break; } lambda *= 5; }
    if (!moved) break; }
  const { v, p } = unpack(x); return { ok: err < 1e-9, err, v, p }; }

const port = k => ({ lambda11: k, lambda12: k, lambda21: k, lambda22: k, lambda41: k, lambda42: k, lambda51: k, lambda52: k });
// Brazilian targets, per quarter. Sources in CALIBRATION.md.
// The tax rate is not a target: at rest the budget balances, so taxes must cover government consumption
// plus interest, and the rate follows from the other targets. Output keeps the book's size.
const TARGETS = { government: 0.188, imports: 0.175, debt: 3.28, foreignShare: 0.099, output: 97.394 };
const brazilFree = ['theta_uk', 'g_k_uk', 'mu0', 'alpha2_uk', 'lambda50', 'eps0'];
const brazilTargets = [
  (v) => v.g_uk / v.y_uk - TARGETS.government, (v) => v.im_uk / v.y_uk - TARGETS.imports,
  (v) => v.b_uk_s / v.y_uk - TARGETS.debt, (v) => v.b_usuk_s / v.b_uk_s - TARGETS.foreignShare,
  (v) => v.y_k_uk / TARGETS.output - 1, (v) => v.xr_uk - 1 ];
module.exports = { rest, port, TARGETS, brazilFree, brazilTargets };

if (require.main === module) {
  const start = JSON.parse(require('fs').readFileSync(__dirname + '/steady.json'));
  const f = (x, d = 3) => x.toFixed(d);
  const ratios = v => `y ${f(v.y_k_uk, 1)} xr ${f(v.xr_uk)} | taxes ${f(v.t_uk / v.y_uk)} gov ${f(v.g_uk / v.y_uk)} imports ${f(v.im_uk / v.y_uk)} exports ${f(v.x_uk / v.y_uk)} cons ${f(v.cons_uk / v.y_uk)} debt ${f(v.b_uk_s / v.y_uk)} foreign ${f(v.b_usuk_s / v.b_uk_s)} money/y ${f(v.h_uk_d / v.y_uk)} cb share ${f(v.b_cb_ukuk_d / v.b_uk_s)} cab ${f(v.cab_uk, 6)} psbr ${f(v.psbr_uk, 6)} | us y ${f(v.y_k_us, 1)}`;
  const a = rest(m.P0, start); console.log('book          ', a.ok, a.err.toExponential(1), ratios(a.v));
  const worst = Math.max(...KEYS.map(k => Math.abs(a.v[k] - start[k]) / Math.max(1, Math.abs(start[k])))); console.log('  distance from the settled start:', worst.toExponential(1));
  for (const [label, base] of [['book trade', {}], ['brazil trade', { eps1: .01, mu1: .55 }], ['r 1.5% 0.5%', { r_uk: .015, r_us: .005 }]]) {
    const p = { ...m.P0, ...port(2), r_uk: .036, r_us: .01, ...base };
    const b = rest(p, start, brazilFree, brazilTargets);
    console.log(label.padEnd(14), b.ok, b.err.toExponential(1), ratios(b.v)); console.log('  free:', brazilFree.map(k => k + ' ' + f(b.p[k], 4)).join(', '));
    // is it really at rest? run the model from it
    const run = m.run(40, [], b.v, b.p); const z = run.out.at(-1); console.log('  after 40 periods at rest:', run.failedAt ? 'FAIL@' + run.failedAt : `xr ${f(z.xr_uk, 6)} y ${f(z.y_k_uk, 4)} cab ${f(z.cab_uk, 6)}`);
  }
}
