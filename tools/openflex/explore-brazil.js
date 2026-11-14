const m = require('./model.js'); const start = JSON.parse(require('fs').readFileSync(__dirname + '/steady.json'));
const port = k => ({ lambda11: k, lambda12: k, lambda21: k, lambda22: k, lambda41: k, lambda42: k, lambda51: k, lambda52: k });
const f = (x, d = 3) => x.toFixed(d);
function show(label, set, n = 3000) {
  // phase the change in gradually to stay inside the solver's reach
  const steps = 200, shocks = [];
  for (let i = 1; i <= steps; i++) { const s = {}; for (const k in set) s[k] = m.P0[k] + (set[k] - m.P0[k]) * i / steps; shocks.push({ at: i, set: s }); }
  const r = m.run(n, shocks, start); const z = r.out.at(-1), y = r.out.at(-2);
  if (r.failedAt) return console.log(label, 'FAIL@' + r.failedAt);
  console.log(label.padEnd(26), `drift xr ${(z.xr_uk / y.xr_uk - 1).toExponential(1)} | xr ${f(z.xr_uk)} debt/y ${f(z.b_uk_s / z.y_uk)} tax/y ${f(z.t_uk / z.y_uk)} g/y ${f(z.g_uk / z.y_uk)} im/y ${f(z.im_uk / z.y_uk)} x/y ${f(z.x_uk / z.y_uk)} cons/y ${f(z.cons_uk / z.y_uk)} foreign share ${f(z.b_usuk_s / z.b_uk_s)} cab/y ${f(z.cab_uk / z.y_uk, 4)} psbr/y ${f(z.psbr_uk / z.y_uk, 4)} y ${f(z.y_k_uk, 1)}`);
  return z;
}
show('book', {});
const br = { theta_uk: 0.324, alpha2_uk: 0.05, ...port(0.5) };
show('tax+alpha2+port', br);
show('+ r 3.6%/q', { ...br, r_uk: 0.036 });
show('+ r_us 1%', { ...br, r_uk: 0.036, r_us: 0.01 });
show('+ imports 17.5%', { ...br, mu0: -1.75, eps0: -1.75 });
show('+ g', { ...br, mu0: -1.75, eps0: -1.75, g_k_uk: 20 });
show('+ BR trade', { ...br, eps1: .01, mu1: .55 });
