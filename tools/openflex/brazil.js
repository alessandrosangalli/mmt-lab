// The Brazilian starting point: a resting point of the model with Brazilian proportions, per quarter.
// Usage: node tools/openflex/brazil.js [path of the Elm module to write]
const m = require('./model.js'); const c = require('./calibrate.js'); const fs = require('fs');
const start = JSON.parse(fs.readFileSync(__dirname + '/steady.json'));

// Policy at rest, on the screen's slider steps. 3.5% a quarter is 14.75% a year.
const POLICY = { g_k_uk: 18, theta_uk: 0.27, r_uk: 0.035 };
// Premises at rest: the Brazilian values read so far (CALIBRATION.md).
const PREMISES = { eps1: 0.01, mu1: 0.55, nu1m: 0.7, port: 2 };
const FOREIGN_RATE = 0.01; // provisional, no source read yet
const TARGETS = { imports: 0.175, debt: 3.28, foreignShare: 0.099 };

const base = { ...m.P0, ...POLICY, ...c.port(PREMISES.port), eps1: PREMISES.eps1, mu1: PREMISES.mu1, nu1m: PREMISES.nu1m, r_us: FOREIGN_RATE };
const found = c.rest(base, start, ['mu0', 'alpha2_uk', 'lambda50', 'eps0'], [
  v => v.im_uk / v.y_uk - TARGETS.imports, v => v.b_uk_s / v.y_uk - TARGETS.debt,
  v => v.b_usuk_s / v.b_uk_s - TARGETS.foreignShare, v => v.xr_uk - 1]);
if (!found.ok) throw new Error('no resting point found: ' + found.err);
// polish: step the model from the point found until it stops moving at machine precision
let rest = found.v; for (let i = 0; i < 5; i++) rest = m.run(1, [], rest, found.p).out[0];
const P = found.p; const V = {}; for (const k of m.KEYS) V[k] = rest[k];

// Premises re-anchored on the resting point: whatever their values, the economy starts at rest.
// Mirrors `toParams` in src/Model/Brazil.elm.
function withPremises(chosen, policy = {}) {
  const gap = P.r_uk - P.r_us, was = P.lambda11, k = chosen.port;
  const relImports = Math.log(V.pm_uk / V.py_uk), relExports = Math.log(V.pm_us / V.py_us);
  const passBase = Math.log(V.py_us) - Math.log(V.py_uk) - Math.log(V.xr_uk);
  return { ...P, ...policy, ...c.port(k), eps1: chosen.eps1, mu1: chosen.mu1, nu1m: chosen.nu1m,
    lambda10: P.lambda10 + (was - k) * gap, lambda20: P.lambda20 - (was - k) * gap,
    lambda40: P.lambda40 - (was - k) * gap, lambda50: P.lambda50 + (was - k) * gap,
    eps0: P.eps0 + (chosen.eps1 - P.eps1) * relExports, mu0: P.mu0 + (chosen.mu1 - P.mu1) * relImports,
    nu0m: P.nu0m - (chosen.nu1m - P.nu1m) * passBase }; }
module.exports = { P, V, withPremises, PREMISES, POLICY };

if (require.main === module) {
  const f = (x, d = 4) => x.toFixed(d);
  console.log('rest:', `y ${f(V.y_k_uk)} xr ${f(V.xr_uk, 8)} taxes/y ${f(V.t_uk / V.y_uk)} gov/y ${f(V.g_uk / V.y_uk)} imports/y ${f(V.im_uk / V.y_uk)} exports/y ${f(V.x_uk / V.y_uk)} cons/y ${f(V.cons_uk / V.y_uk)} debt/y ${f(V.b_uk_s / V.y_uk)} foreign ${f(V.b_usuk_s / V.b_uk_s)} money/y ${f(V.h_uk_d / V.y_uk)} us y ${f(V.y_k_us)}`);
  console.log('solved:', ['mu0', 'alpha2_uk', 'lambda50', 'eps0'].map(k => k + ' ' + P[k]).join(', '));
  // the economy stays at rest whatever the premises
  for (const ch of [PREMISES, { eps1: .7, mu1: .7, nu1m: .7, port: 5 }, { eps1: 0, mu1: 1, nu1m: .3, port: 0 }, { eps1: .5, mu1: .8, nu1m: 1, port: 10 }]) {
    const p = withPremises(ch); const r = m.run(60, [], V, p); const z = r.out.at(-1);
    console.log('at rest with', JSON.stringify(ch), r.failedAt ? 'FAIL@' + r.failedAt : `drift y ${(z.y_k_uk / V.y_k_uk - 1).toExponential(1)} xr ${(z.xr_uk / V.xr_uk - 1).toExponential(1)}`); }
  // reference numbers for the Elm tests
  const book = { eps1: .7, mu1: .7, nu1m: .7, port: 2 };
  const show = (label, ch, policy, n = 120) => { const r = m.run(n, [{ at: 1, set: withPremises(ch, policy) }], V, withPremises(ch)); const o = r.out;
    const col = o.length ? Math.max(...o.map(x => Math.max(...Object.values(m.tfm(x)).map(Math.abs)))) : NaN;
    console.log(label.padEnd(34), r.failedAt ? 'FAIL@' + r.failedAt : 'ok', o[0] ? `t1 xr ${o[0].xr_uk.toFixed(10)} y ${o[0].y_k_uk.toFixed(7)}` : '', o[39] ? `t40 xr ${o[39].xr_uk.toFixed(10)}` : '', o[119] ? `t120 xr ${o[119].xr_uk.toFixed(10)} y ${o[119].y_k_uk.toFixed(7)} cab ${o[119].cab_uk.toFixed(10)} p ${o[119].pds_uk.toFixed(10)}` : '', 'tfm', col.toExponential(1)); };
  show('default, g 19', PREMISES, { g_k_uk: 19 }); show('book trade, g 19', book, { g_k_uk: 19 });
  show('default, r 4%', PREMISES, { r_uk: .04 }); show('book trade, r 4%', book, { r_uk: .04 });
  show('default, r 3%', PREMISES, { r_uk: .03 }); show('default, tax 28', PREMISES, { theta_uk: .28 });
  show('default, r 6%', PREMISES, { r_uk: .06 }); show('default, g 25', PREMISES, { g_k_uk: 25 });
  const out = process.argv[2]; if (out) {
    const lit = x => { let s = String(Math.abs(x)); if (/e/.test(s) && !/\./.test(s)) s = s.replace('e', '.0e'); return (x < 0 ? '-' : '') + s; };
    const rec = (o, keys) => keys.map((k, i) => `    ${i ? ',' : '{'} ${k} = ${lit(o[k])}`).join('\n') + '\n    }';
    fs.writeFileSync(out, `module Model.BrazilRest exposing (params, vars)

{-| The Brazilian starting point of model OPENFLEX: a resting point whose
proportions are Brazil's, with the period read as a quarter.

Generated by \`tools/openflex/brazil.js\`, which solves the resting point as a
system of equations. \`CALIBRATION.md\` says where each target comes from.

-}

import Model.OpenFlex exposing (Params, Vars)


{-| The parameters under which the economy rests at \`vars\`.
-}
params : Params
params =
${rec(P, Object.keys(m.P0))}


{-| The resting point: stepping from here changes nothing.
-}
vars : Vars
vars =
${rec(V, m.KEYS)}
`); console.log('wrote', out); }
}
