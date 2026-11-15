// The Brazilian starting point: a growth path of the model with Brazilian proportions, per quarter.
// Usage: node tools/openflex/brazil.js [path of the Elm module to write]
const m = require('./model.js'); const c = require('./calibrate.js'); const fs = require('fs');
const start = JSON.parse(fs.readFileSync(__dirname + '/steady.json'));
const quarterly = yearly => Math.pow(1 + yearly, 0.25);

// Policy on the path, on the screen's slider steps. 3.5% a quarter is 14.75% a year.
const POLICY = { g_k_uk: 18, theta_uk: 0.39, r_uk: 0.035 };
// Premises on the path: the Brazilian values read so far (CALIBRATION.md).
const PREMISES = { eps1: 0.01, mu1: 0.55, nu1m: 1, port: 2 };
// Trends and the foreign interest rate (CALIBRATION.md, section 8).
const WORLD = { trend: quarterly(0.023), infl_uk: quarterly(0.046), infl_us: quarterly(0.02), r_us: 0.0096 };
// Direct investment inflow and exports, as shares of output (CALIBRATION.md, section 8).
const EXTERNAL = { directInvestment: 0.0358, exports: 0.178 };
// Share of wages re-optimized each quarter: 1 minus the wage Calvo probability of the Banco Central's SAMBA
// model, 0.784 (Fasolo et al. 2023, BCB Working Paper 578, table 4). CALIBRATION.md, section 2.
const WAGE_RESET = 0.216;
const TARGETS = { imports: 0.175, debt: 3.28, foreignShare: 0.099, government: 0.191 };

const expected = p => ({ dxre_us: p.infl_uk / p.infl_us - 1, dxre_uk: p.infl_us / p.infl_uk - 1 }); // the trend of each exchange rate
function solvePath(world = WORLD, external = EXTERNAL) {
const flat = world.trend * world.infl_uk === 1;
const base = { ...m.P0, ...c.port(PREMISES.port), eps1: PREMISES.eps1, mu1: PREMISES.mu1, nu1m: PREMISES.nu1m, ...world, ...expected(world) };
const T = { imports: v => v.im_uk / v.y_uk - TARGETS.imports, debt: v => v.b_uk_s / v.y_uk - TARGETS.debt,
  foreign: v => v.b_usuk_s / v.b_uk_s - TARGETS.foreignShare, rate: v => v.xr_uk - 1, government: v => v.g_uk / v.y_uk - TARGETS.government };
const shape = ['mu0', 'alpha2_uk', 'lambda50', 'eps0'], shapeTargets = [T.imports, T.debt, T.foreign, T.rate];
// Far from the book's starting point the solver needs to be led: growth and inflation are switched on a
// little at a time, with the size of the book's economy and the tax rate free; then the tax rate is
// walked up to the policy's.
const stage = [...shape, 'theta_uk', 'tr_k_uk', 'g_k_uk'];
const stageTargets = [...shapeTargets, T.government, v => v.t_uk / v.y_uk - 0.324, v => v.y_k_uk / 94.8344 - 1];
let found = { p: null, v: start }; const STEPS = 8;
for (let k = 1; k <= STEPS; k++) { const part = { trend: Math.pow(world.trend, k / STEPS), infl_uk: Math.pow(world.infl_uk, k / STEPS), infl_us: Math.pow(world.infl_us, k / STEPS) };
  found = c.rest({ ...(found.p || base), r_uk: POLICY.r_uk, r_us: world.r_us, ...part, ...expected(part) }, found.v, stage, stageTargets, flat);
  if (!found.ok) throw new Error('growth stage ' + k + ' failed: ' + found.err); }
for (let theta = 0.30; theta < POLICY.theta_uk + 0.005; theta += 0.01) {
  found = c.rest({ ...found.p, ...POLICY, theta_uk: Math.min(theta, POLICY.theta_uk) }, found.v, [...shape, 'tr_k_uk'], [...shapeTargets, T.government], flat);
  if (!found.ok) throw new Error('no growth path found at tax rate ' + theta + ': ' + found.err); }
found.p.theta_uk = POLICY.theta_uk;
// Direct investment is switched on a little at a time. The profit rate foreign-owned firms send abroad is
// solved so that exports land on their share of output. The current account is then a result: on a
// growth path it is pinned by the stocks of foreign assets and liabilities.
const pathExports = found.v.x_uk / found.v.y_uk;
for (let k = 1; external && k <= STEPS; k++) { const share = k / STEPS, aim = pathExports + (external.exports - pathExports) * share;
  found = c.rest({ ...found.p, fdi_flow_uk: external.directInvestment * share }, found.v, [...shape, 'tr_k_uk', 'rho_uk'],
    [...shapeTargets, T.government, v => v.x_uk / v.y_uk - aim], false);
  if (!found.ok) throw new Error('direct investment stage ' + k + ' failed: ' + found.err); }
// polish: step the model from the point found until it stops moving at machine precision
let rest = found.v; for (let i = 0; i < 5; i++) rest = m.run(1, [], rest, found.p).out[0];
const V = {}; for (const k of m.KEYS) V[k] = rest[k];
// Wages: a quarter of them are reset each quarter, and by default they do not follow prices (kappa 0).
// The reference price level is the path's own.
return { P: { ...found.p, pref_uk: V.pds_uk, wspeed_uk: WAGE_RESET, kappa_uk: 0 }, V }; }
const { P, V } = solvePath();

// Premises re-anchored on the path: whatever their values, the economy starts on it.
// Mirrors `toParams` in src/Model/Brazil.elm.
function withPremises(chosen, policy = {}, at = { P, V }) { const P = at.P, V = at.V;
  const home = P.r_uk - P.r_us - P.dxre_us, abroad = P.r_us - P.r_uk - P.dxre_uk, change = P.lambda11 - chosen.port;
  const relImports = Math.log(V.pm_uk / V.py_uk), relExports = Math.log(V.pm_us / V.py_us);
  const passBase = Math.log(V.py_us) - Math.log(V.py_uk) - Math.log(V.xr_uk);
  return { ...P, ...policy, ...c.port(chosen.port), eps1: chosen.eps1, mu1: chosen.mu1, nu1m: chosen.nu1m, kappa_uk: chosen.kappa || 0,
    lambda10: P.lambda10 + change * home, lambda20: P.lambda20 - change * home,
    lambda40: P.lambda40 + change * abroad, lambda50: P.lambda50 - change * abroad,
    eps0: P.eps0 + (chosen.eps1 - P.eps1) * relExports, mu0: P.mu0 + (chosen.mu1 - P.mu1) * relImports,
    nu0m: P.nu0m - (chosen.nu1m - P.nu1m) * passBase }; }
// The same economy on other trends: walks growth and inflation from a known path to `world` in small steps.
function moveTo(world, from, steps = 8) { let at = from; const was = from.P;
  const target = [v => v.im_uk / v.y_uk - TARGETS.imports, v => v.b_uk_s / v.y_uk - TARGETS.debt, v => v.b_usuk_s / v.b_uk_s - TARGETS.foreignShare,
    v => v.xr_uk - 1, v => v.g_uk / v.y_uk - TARGETS.government];
  for (let k = 1; k <= steps; k++) { const mix = key => Math.pow(was[key], 1 - k / steps) * Math.pow(world[key], k / steps);
    const part = { trend: mix('trend'), infl_uk: mix('infl_uk'), infl_us: mix('infl_us') };
    const r = c.rest({ ...at.P, ...part, ...expected(part) }, at.V, ['mu0', 'alpha2_uk', 'lambda50', 'eps0', 'tr_k_uk'], target, part.trend * part.infl_uk === 1);
    if (!r.ok) throw new Error('step ' + k + ' failed: ' + r.err); at = { P: r.p, V: r.v }; }
  let rest = at.V; for (let i = 0; i < 5; i++) rest = m.run(1, [], rest, at.P).out[0];
  const V = {}; for (const k of m.KEYS) V[k] = rest[k]; return { P: at.P, V }; }
module.exports = { P, V, withPremises, PREMISES, POLICY, WORLD, solvePath, moveTo };

if (require.main === module) {
  const f = (x, d = 4) => x.toFixed(d); const L = m.carry(V, P);
  console.log('path:', `y ${f(V.y_k_uk)} xr ${f(V.xr_uk, 8)} revenue/y ${f(V.t_uk / V.y_uk)} gov/y ${f(V.g_uk / V.y_uk)} transfers/y ${f(V.tr_uk / V.y_uk)} interest/y ${f(P.r_uk * L.b_uk_s / V.y_uk)} deficit/y ${f(V.psbr_uk / V.y_uk)} imports/y ${f(V.im_uk / V.y_uk)} exports/y ${f(V.x_uk / V.y_uk)} cons/y ${f(V.cons_uk / V.y_uk)} debt/y ${f(V.b_uk_s / V.y_uk)} foreign ${f(V.b_usuk_s / V.b_uk_s)} cab/y ${f(V.cab_uk / V.y_uk)} direct investment stock/y ${f(V.fdi_uk / V.y_uk)} profits sent/y ${f(V.remit_uk / V.y_uk)} rho ${f(P.rho_uk, 5)} trade balance/y ${f((V.x_uk - V.im_uk) / V.y_uk)} foreign bills/wealth ${f(V.b_ukus_d / V.v_uk)} us y ${f(V.y_k_us)}`);
  console.log('solved:', ['mu0', 'alpha2_uk', 'lambda50', 'eps0', 'tr_k_uk', 'rho_uk'].map(k => k + ' ' + P[k]).join(', '));
  for (const ch of [PREMISES, { eps1: .7, mu1: .7, nu1m: .7, port: 5 }, { eps1: 0, mu1: 1, nu1m: .3, port: 0 }, { eps1: .5, mu1: .8, nu1m: 1, port: 10 }]) {
    const p = withPremises(ch); const r = m.run(60, [], V, p); const z = r.out.at(-1);
    console.log('on the path with', JSON.stringify(ch), r.failedAt ? 'FAIL@' + r.failedAt : `drift y ${(z.y_k_uk / V.y_k_uk - 1).toExponential(1)} xr ${(z.xr_uk / V.xr_uk - 1).toExponential(1)}`); }
  const book = { eps1: .7, mu1: .7, nu1m: .7, port: 2 };
  const show = (label, ch, policy, n = 120) => { const r = m.run(n, [{ at: 1, set: withPremises(ch, policy) }], V, withPremises(ch)); const o = r.out;
    const col = o.length ? Math.max(...o.map(x => Math.max(...Object.values(m.tfm(x)).map(Math.abs)))) : NaN;
    const at = i => o[i - 1] ? `t${i} xr ${o[i - 1].xr_uk.toFixed(10)} y ${o[i - 1].y_k_uk.toFixed(7)} cab ${o[i - 1].cab_uk.toFixed(10)} debt/y ${f(o[i - 1].b_uk_s / o[i - 1].y_uk, 3)} p ${(o[i - 1].pds_uk / V.pds_uk).toFixed(10)}` : '';
    console.log(label.padEnd(34), r.failedAt ? 'FAIL@' + r.failedAt : 'ok', at(1), '|', at(40), '|', at(120), '| tfm', col.toExponential(1)); };
  show('default, g 19', PREMISES, { g_k_uk: 19 }); show('wages follow prices 0.9, g 19', { ...PREMISES, kappa: 0.9 }, { g_k_uk: 19 }); show('wages follow prices 1, nothing', { ...PREMISES, kappa: 1 }, {}); show('book trade, g 19', book, { g_k_uk: 19 });
  show('default, g 17', PREMISES, { g_k_uk: 17 });
  show('default, r 4%', PREMISES, { r_uk: .04 }); show('book trade, r 4%', book, { r_uk: .04 });
  show('default, r 3%', PREMISES, { r_uk: .03 }); show('default, tax 40', PREMISES, { theta_uk: .40 });
  show('default, r 6%', PREMISES, { r_uk: .06 }); show('default, g 25', PREMISES, { g_k_uk: 25 });
  show('default, g 19, 400 periods', PREMISES, { g_k_uk: 19 }, 400);
  const out = process.argv[2]; if (out) {
    const lit = x => { let s = String(Math.abs(x)); if (/e/.test(s) && !/\./.test(s)) s = s.replace('e', '.0e'); return (x < 0 ? '-' : '') + s; };
    const rec = (o, keys) => keys.map((k, i) => `    ${i ? ',' : '{'} ${k} = ${lit(o[k])}`).join('\n') + '\n    }';
    fs.writeFileSync(out, `module Model.BrazilRest exposing (params, vars)

{-| The Brazilian starting point of model OPENFLEX: a growth path whose
proportions are Brazil's, with the period read as a quarter.

Every value is measured relative to its trend, so on the path nothing moves:
the economy, its prices and the public debt all grow at their trend rates.

Generated by \`tools/openflex/brazil.js\`, which solves the path as a system of
equations. \`CALIBRATION.md\` says where each target comes from.

-}

import Model.OpenFlex exposing (Params, Vars)


{-| The parameters under which the economy stays at \`vars\`.
-}
params : Params
params =
${rec(P, Object.keys(m.P0))}


{-| The starting point: stepping from here changes nothing.
-}
vars : Vars
vars =
${rec(V, m.KEYS)}
`); console.log('wrote', out); }
}
