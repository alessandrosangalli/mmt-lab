// Tries to calibrate the brake of the real interest rate on consumption (zeta) in the Brazilian model.
// Experiment: the real interest rate is held one point a year (0.25 a quarter) above its rate on the starting
// path, by moving the nominal rate each quarter with last quarter's inflation. Target: the output path the
// central bank's IS curve gives for the same gap, h = 0.85 h(-1) - 0.44 gap (Banco Central 2024, table 1),
// over the first eight quarters. The script shows why that calibration cannot be done in the model as it is:
// holding the real rate makes the model explode, and holding the nominal rate lets inflation undo the brake.
// Usage: node tools/openflex/brake.js
const m = require('./model.js'); const b = require('./brazil.js');
const V = b.V, GAP = 0.0025, QUARTERS = 8;
const target = []; for (let t = 1, h = 0; t <= 20; t++) { h = 0.85 * h - 0.44; target.push(h); }
function path(premises, quarters = QUARTERS) {
  const base = b.withPremises(premises); let state = V, last = base, inflation = base.infl_uk; const out = [];
  for (let t = 1; t <= quarters; t++) {
    const p = { ...base, r_uk: base.rstar_uk + (inflation - 1) + GAP };
    const r = m.run(1, [{ at: 1, set: p }], state, last); if (r.failedAt) return null;
    state = r.out[0]; last = p; inflation = state.gpi_uk; out.push(100 * Math.log(state.y_k_uk / V.y_k_uk)); }
  return out; }
const show = xs => xs ? [1, 2, 4, 8, 12, 20].map(t => xs[t - 1] === undefined ? `t${t} --` : `t${t} ${xs[t - 1].toFixed(2)}`).join('  ') : 'no solution';
function partial(premises, quarters) { const base = b.withPremises(premises); let state = V, last = base, inflation = base.infl_uk; const out = [];
  for (let t = 1; t <= quarters; t++) { const p = { ...base, r_uk: base.rstar_uk + (inflation - 1) + GAP };
    const r = m.run(1, [{ at: 1, set: p }], state, last); if (r.failedAt) return { out, failedAt: t };
    state = r.out[0]; last = p; inflation = state.gpi_uk; out.push(100 * Math.log(state.y_k_uk / V.y_k_uk)); }
  return { out }; }
console.log('IS curve, real rate held 1 point a year above neutral:', show(target));
for (const zeta of [0, 2, 5]) { const r = partial({ ...b.PREMISES, zeta }, 20);
  console.log(`real rate held, brake ${zeta}:`.padEnd(30), show(r.out), r.failedAt ? `  no solution from quarter ${r.failedAt}` : ''); }
for (const zeta of [0, 2, 4, 6]) { const base = b.withPremises({ ...b.PREMISES, zeta }); const r = m.run(120, [{ at: 1, set: { ...base, r_uk: base.r_uk + GAP } }], V, base);
  console.log(`nominal rate held, brake ${zeta}:`.padEnd(30), show(r.out.map(z => 100 * Math.log(z.y_k_uk / V.y_k_uk))), `  t120 ${(100 * Math.log(r.out[119].y_k_uk / V.y_k_uk)).toFixed(2)}`); }
