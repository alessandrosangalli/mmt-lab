// Why does growth steady the exchange rate? Solves the Brazilian starting point for several rates of
// growth and inflation (without direct investment, so that a point of rest exists with no growth), gives
// each a small permanent rise in government spending, and measures how the exchange rate's movement dies
// out or builds up: `ratio` is this period's movement over last period's, late in the run. Below 1 the
// economy settles; at 1 or above it never does.
// The last case is the model on the screen, which has direct investment.
// Usage: node tools/openflex/stability.js
const m = require('./model.js'); const b = require('./brazil.js');
const q = yearly => Math.pow(1 + yearly, 0.25);
const full = b.solvePath(b.WORLD, null);
function measure(world, premises) {
  let at; try { at = world === 'screen' ? { P: b.P, V: b.V } : b.moveTo({ ...b.WORLD, ...world }, full); } catch (e) { return 'no starting point (' + e.message.slice(0, 40) + ')'; }
  const base = b.withPremises(premises, {}, at), shocked = b.withPremises(premises, { g_k_uk: at.P.g_k_uk + 0.1 }, at);
  const r = m.run(800, [{ at: 1, set: shocked }], at.V, base); const o = r.out; if (o.length < 60) return 'no solution from period ' + r.failedAt;
  const move = t => o[t].xr_uk - o[t - 1].xr_uk;
  // measure where the rate is still moving by more than rounding error
  let n = o.length - 1; while (n > 40 && Math.abs(move(n)) < 1e-9) n--;
  let ratio = 0, count = 0; for (let t = n - 20; t <= n; t++) { ratio += move(t) / move(t - 1); count++; } ratio /= count;
  const half = ratio < 1 ? Math.log(0.5) / Math.log(ratio) : Infinity;
  return `ratio ${ratio.toFixed(5)}  half-life ${isFinite(half) ? half.toFixed(0).padStart(4) + ' quarters' : '  never'}  rate at the end ${(o[o.length - 1].xr_uk).toFixed(4)}  debt/y ${(o[o.length - 1].b_uk_s / o[o.length - 1].y_uk).toFixed(3)}${r.failedAt ? '  NO SOLUTION from ' + r.failedAt : ''}`; }
const brazil = b.PREMISES, book = { ...b.PREMISES, eps1: 0.7, mu1: 0.7 };
const cases = [
  ['no growth, no inflation', { trend: 1, infl_uk: 1, infl_us: 1 }],
  ['a quarter of both', { trend: q(0.023 / 4), infl_uk: q(0.046 / 4), infl_us: q(0.02 / 4) }],
  ['half of both', { trend: q(0.023 / 2), infl_uk: q(0.046 / 2), infl_us: q(0.02 / 2) }],
  ['both in full (Brazil)', {}],
  ['real growth only', { infl_uk: 1, infl_us: 1 }],
  ['inflation only', { trend: 1 }],
  ['home inflation only', { trend: 1, infl_us: 1 }],
  ['the model on screen', 'screen'], // with direct investment
];
for (const [label, world] of cases) { console.log(label.padEnd(26), 'Brazilian trade:', measure(world, brazil)); console.log(''.padEnd(26), 'book trade:     ', measure(world, book)); }
