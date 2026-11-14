const gen = require('./gen.js'); const m = require('./model.js'); const fs = require('fs');
const steady = JSON.parse(fs.readFileSync(__dirname + '/steady.json'));
const names = gen.names; const P = m.P0; const pk = Object.keys(P);
const num = x => { let s = String(x); if (!/[.e]/.test(s)) return s; return s; };
const lit = x => x < 0 ? `-${num(-x)}` : num(x);
const rec = (keys, f, ind) => keys.map((k, i) => `${ind}${i ? ',' : '{'} ${k} ${f(k)}`).join('\n') + `\n${ind}}`;
const eqs = gen.elm();
let out = `module Model.OpenFlex exposing
    ( Failure
    , Params
    , Vars
    , bookParams
    , carry
    , flows
    , sectors
    , simulate
    , steadyState
    , step
    )

{-| Model OPENFLEX from Godley and Lavoie, "Monetary Economics" (2007),
chapter 12: two countries that trade goods and hold each other's bills, with
a floating exchange rate.

The book calls the countries UK and US. Here the UK plays the home country:
it sets its own interest rate and lets its currency float. \`xr_uk\` is the
value of the home currency in units of the foreign one, so a fall is a
depreciation.

Variable and parameter names are the book's, kept as they are so that each
line can be checked against the book and against the \`sfcr\` replication the
equations were taken from. A \`_k\` marks a real (volume) quantity, \`_d\` a
demand and \`_s\` a supply. \`b_ukus\` are US bills held in the UK, \`b_usuk\` UK
bills held in the US, and \`b_cb\` the holdings of a central bank.

Two things differ from the book. Gold is left out: it never changes hands in
this version of the model, so it only added a constant to each central
bank's balance sheet. And the home central bank's bill holdings follow the
book's own alternative equation 12.82A (it holds the bills nobody else
does), which keeps the accounts from drifting apart over long runs.

Three things are added, and all are switched off in the book's baseline. The
home government can pay transfers to households (\`tr_k_uk\`). Foreigners can
buy a share of home firms from home households every period (\`fdi_flow_uk\`,
as a share of output) and receive profits on what they own (\`rho_uk\`). And
the economy can sit on a growth path: every value is measured relative to its
trend, where real quantities grow at \`trend\` a period and each country's
prices at its \`infl\`. See \`carry\`.

The body of \`sweep\`, the list of fields and the steady state are generated
from one list of equations, the same list that produced the prototype these
numbers were checked against.

-}

import Sfc.Matrix exposing (Flow, Sector(..))
import Sfc.Solver as Solver



-- PARAMETERS


type alias Params =
${rec(pk, k => ': Float', '    ')}


{-| The book's baseline. Both countries are identical.
-}
bookParams : Params
bookParams =
${rec(pk, k => '= ' + lit(P[k]), '    ')}



-- VARIABLES


type alias Vars =
${rec(names, k => ': Float', '    ')}


{-| The steady state of the baseline: stepping from here changes nothing.
-}
steadyState : Vars
steadyState =
${rec(names, k => '= ' + lit(steady[k]), '    ')}



-- TRENDS


{-| Last period's values, measured against this period's trend.

Real quantities grow at \`trend\` a period, each country's prices at its
\`infl\`, amounts of money at both, and an exchange rate at the ratio of the
two inflations. So relative to this period's trend, last period's value is
smaller by one period of growth. With no growth and no inflation this
changes nothing.

-}
carry : Params -> Vars -> Vars
carry params vars =
${rec(names, k => '= vars.' + k + ' / ' + gen.factor(k, 'params'), '    ')}



-- EQUATIONS


exp : Float -> Float
exp x =
    e ^ x


ln : Float -> Float
ln x =
    logBase e x


{-| One pass over every equation, in order. Each one uses the values already
computed in this pass where there are any, and the previous guess otherwise.
A period is solved by repeating the pass until nothing changes. \`lagged\` is
the previous period as \`carry\` returns it.

The comment above each line is the equation's number in the book.

-}
sweep : Params -> Vars -> Params -> Vars -> Vars
sweep laggedParams lagged params guess =
    let
${eqs.map(e => `        -- ${e.comment}\n        ${e.name} =\n            ${e.expr}`).join('\n\n')}
    in
${rec(names, k => '= ' + k, '    ')}


relativeChange : Float -> Float -> Float
relativeChange before after =
    abs (after - before) / max 1 (abs before)


worst : Float -> Float -> Float
worst term soFar =
    if isNaN term || isNaN soFar then
        0 / 0

    else
        max term soFar


{-| The largest relative change in any variable between two passes.
-}
distance : Vars -> Vars -> Float
distance before after =
    List.foldl worst
        0
${names.map((k, i) => `        ${i ? ',' : '['} relativeChange before.${k} after.${k}`).join('\n')}
        ]



-- SOLVING


{-| Solve one period, given the previous period and the parameters then and
now. Fails, rather than returning nonsense, when the passes do not settle.
-}
step : Params -> Vars -> Params -> Result Solver.Error Vars
step laggedParams lagged params =
    Solver.fixedPoint
        { sweep = sweep laggedParams (carry params lagged) params
        , distance = distance
        , tolerance = 1.0e-12
        , maxSweeps = 500
        }
        lagged


type alias Failure =
    { period : Int
    , error : Solver.Error
    }


{-| Run a number of periods from the steady state. \`paramsAt\` gives the
parameters in force in each period; period 0 is the period before the first.
-}
simulate : (Int -> Params) -> Int -> Result Failure (List Vars)
simulate paramsAt periods =
    simulateFrom paramsAt periods 1 steadyState []


simulateFrom : (Int -> Params) -> Int -> Int -> Vars -> List Vars -> Result Failure (List Vars)
simulateFrom paramsAt periods period lagged solved =
    if period > periods then
        Ok (List.reverse solved)

    else
        case step (paramsAt (period - 1)) lagged (paramsAt period) of
            Ok vars ->
                simulateFrom paramsAt periods (period + 1) vars (vars :: solved)

            Err error ->
                Err { period = period, error = error }



-- TRANSACTION FLOWS


sectors : List Sector
sectors =
    [ Households, Firms, Government, CentralBank, RestOfWorld ]


{-| The home country's payments in a period, in its own currency, with the
foreign country as a single sector. Capital gains from the exchange rate are
not payments, so they do not appear: foreign bills enter at what was paid for
them in the period. \`lagged\` is the previous period as \`carry\` returns it.
-}
flows : Params -> Vars -> Params -> Vars -> List Flow
flows laggedParams lagged params vars =
    [ Flow "Consumo" Households Firms vars.cons_uk
    , Flow "Gasto público" Government Firms vars.g_uk
    , Flow "Exportações" RestOfWorld Firms vars.x_uk
    , Flow "Importações" Firms RestOfWorld vars.im_uk
    , Flow "Renda" Firms Households (vars.y_uk - vars.remit_uk)
    , Flow "Lucros remetidos ao exterior" Firms RestOfWorld vars.remit_uk
    , Flow "Investimento direto recebido" RestOfWorld Households vars.fdi_in_uk
    , Flow "Impostos" Households Government vars.t_uk
    , Flow "Transferências" Government Households vars.tr_uk
    , Flow "Juros dos títulos domésticos das famílias" Government Households (laggedParams.r_uk * lagged.b_ukuk_d)
    , Flow "Juros dos títulos domésticos do banco central" Government CentralBank (laggedParams.r_uk * lagged.b_cb_ukuk_d)
    , Flow "Juros dos títulos domésticos do exterior" Government RestOfWorld (laggedParams.r_uk * lagged.b_usuk_s)
    , Flow "Juros dos títulos estrangeiros das famílias" RestOfWorld Households (vars.xr_us * laggedParams.r_us * lagged.b_ukus_s)
    , Flow "Juros dos títulos estrangeiros do banco central" RestOfWorld CentralBank (vars.xr_us * laggedParams.r_us * laggedParams.b_cb_ukus_s / (params.trend * params.infl_us))
    , Flow "Lucro do banco central" CentralBank Government vars.f_cb_uk
    , Flow "Variação do dinheiro" Households CentralBank (vars.h_uk_d - lagged.h_uk_d)
    , Flow "Variação dos títulos domésticos das famílias" Households Government (vars.b_ukuk_d - lagged.b_ukuk_d)
    , Flow "Variação dos títulos domésticos do banco central" CentralBank Government (vars.b_cb_ukuk_d - lagged.b_cb_ukuk_d)
    , Flow "Variação dos títulos domésticos do exterior" RestOfWorld Government (vars.b_usuk_s - lagged.b_usuk_s)
    , Flow "Variação dos títulos estrangeiros das famílias" Households RestOfWorld ((vars.b_ukus_s - lagged.b_ukus_s) * vars.xr_us)
    , Flow "Variação dos títulos estrangeiros do banco central" CentralBank RestOfWorld ((params.b_cb_ukus_s - laggedParams.b_cb_ukus_s / (params.trend * params.infl_us)) * vars.xr_us)
    ]
`;
fs.writeFileSync(process.argv[2], out);
// expected numbers for the Elm tests
const start = steady; const g = (x) => x.toPrecision(10);
const cases = { s1: [{ at: 5, set: { eps0: -2.2 } }], s2: [{ at: 5, set: { g_k_us: 18 } }], home: [{ at: 5, set: { g_k_uk: 20 } }], rate4: [{ at: 5, set: { r_uk: .04 } }] };
for (const [k, sh] of Object.entries(cases)) { const r = m.run(120, sh, start); const a = r.out[19], z = r.out[119];
  console.log(k, 't20', g(a.xr_uk), g(a.y_k_uk), g(a.cab_uk), g(a.pds_uk), '| t120', g(z.xr_uk), g(z.y_k_uk), g(z.cab_uk)); }
const fail = m.run(120, [{ at: 5, set: { r_uk: .06 } }], start); console.log('rate6 fails at', fail.failedAt, fail.why);
console.log('vars', names.length, 'params', pk.length);
