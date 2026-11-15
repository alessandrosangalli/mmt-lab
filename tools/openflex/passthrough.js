// Calibrates the pass-through of the exchange rate to import prices (nu1m) in the Brazilian model.
// Experiment: residents of both countries move 1% of their wealth from home to foreign bills, once and for
// all. That moves the exchange rate with no change in policy. Target: consumer prices up by 0.10% for each
// 1% of depreciation after four quarters, the central bank's 12-month estimate (CALIBRATION.md, section 2).
// The 24-month estimate, 0.16, is kept apart as a check. Done for the central wage curve and both ends.
// Usage: node tools/openflex/passthrough.js
const m = require('./model.js'); const b = require('./brazil.js');
const V = b.V, TARGET = 0.10, CHECK = 0.16;
const flight = d => base => ({ lambda10: base.lambda10 - d, lambda20: base.lambda20 + d, lambda40: base.lambda40 + d, lambda50: base.lambda50 - d });
function passThrough(premises) { const base = b.withPremises(premises); const o = m.run(8, [{ at: 1, set: { ...base, ...flight(0.01)(base) } }], V, base).out;
  const at = t => Math.log(o[t - 1].pds_uk / V.pds_uk) / Math.log(V.xr_uk / o[t - 1].xr_uk); return [at(4), at(8)]; }
for (const beta of [-0.047, -0.06, -0.08]) { let low = 0, high = 1;
  for (let i = 0; i < 40; i++) { const mid = (low + high) / 2; if (passThrough({ ...b.PREMISES, beta, nu1m: mid })[0] < TARGET) low = mid; else high = mid; }
  const [four, eight] = passThrough({ ...b.PREMISES, beta, nu1m: low });
  console.log(`wage curve ${beta}: nu1m ${low.toFixed(3)} gives ${four.toFixed(3)} at 4 quarters and ${eight.toFixed(3)} at 8 (check: ${CHECK})`); }
const [four, eight] = passThrough(b.PREMISES); console.log(`adopted nu1m ${b.PREMISES.nu1m}: ${four.toFixed(3)} at 4 quarters, ${eight.toFixed(3)} at 8`);
