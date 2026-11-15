// Calibrates the portfolio reaction (port) in the Brazilian model. Experiment: the interest rate rises by a
// quarter point a quarter, one point a year, once and for all. Target: the currency gains 2.5% to 4.2% on
// impact, the range Vicente, Marins and Gaglianone (2021) measure on Copom days (CALIBRATION.md, section 5).
// Usage: node tools/openflex/portfolio.js
const m = require('./model.js'); const b = require('./brazil.js');
const V = b.V, RISE = 0.0025;
function impact(port) { const premises = { ...b.PREMISES, port }; const r = m.run(1, [{ at: 1, set: b.withPremises(premises, { r_uk: b.P.r_uk + RISE }) }], V, b.withPremises(premises));
  return r.failedAt ? NaN : 100 * (r.out[0].xr_uk / V.xr_uk - 1); }
function solve(goal) { let low = 0, high = 10; for (let i = 0; i < 50; i++) { const mid = (low + high) / 2; if (impact(mid) < goal) low = mid; else high = mid; } return (low + high) / 2; }
for (const port of [0, 0.25, 0.5, 1, 2]) console.log(`port ${port}: the currency gains ${impact(port).toFixed(2)}% on impact`);
for (const goal of [2.5, 3.35, 4.2]) console.log(`for ${goal}% on impact: port ${solve(goal).toFixed(3)}`);
console.log(`adopted port ${b.PREMISES.port}: ${impact(b.PREMISES.port).toFixed(2)}%`);
