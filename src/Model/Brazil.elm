module Model.Brazil exposing (defaultPolicy, model, observe, premises, sectors)

{-| Model OPENFLEX started from a growth path with Brazilian proportions,
with the period read as a quarter.

The equations are the book's, plus government transfers and trend growth.
What changes is where the economy starts (`Model.BrazilRest`) and the default
value of each premise, which is the Brazilian one where this project has
read a source. Every value is measured relative to its trend.

-}

import Engine exposing (Snapshot)
import Model.BrazilRest as Rest
import Model.Open as Open exposing (State)
import Model.OpenFlex as OpenFlex exposing (Params)
import Policy exposing (Policy)
import Premise exposing (Premise, Premises)
import Sfc.Matrix exposing (Sector)


sectors : List Sector
sectors =
    Open.sectors


{-| The policy under which the economy stays on its growth path.
-}
defaultPolicy : Policy
defaultPolicy =
    { spending = Rest.params.g_k_uk
    , taxRatePct = Rest.params.theta_uk * 100
    , interestRatePct = Rest.params.r_uk * 100
    }


exportResponse : Premise
exportResponse =
    startingAt Rest.params.eps1 Open.exportResponse


importResponse : Premise
importResponse =
    startingAt Rest.params.mu1 Open.importResponse


{-| In this model wages follow prices and unemployment, so part of a
depreciation reaches consumer prices through wages. The pass-through to
import prices is calibrated again, against the same central bank estimate.
-}
passThrough : Premise
passThrough =
    let
        open =
            startingAt Rest.params.nu1m Open.passThrough
    in
    { open
        | note = "Quanto de uma mudança no câmbio chega ao preço dos importados: 1 é repasse integral. Não há estimativa direta lida. O valor 0,35 é uma calibração indireta: depois de uma saída de capitais que desvaloriza a moeda, é o que faz os preços ao consumidor do modelo subirem 0,10% para cada 1% de desvalorização em quatro trimestres, como estima o Banco Central (2026). A faixa, de 0,28 a 0,43, vem das duas pontas da resposta dos salários ao desemprego. Em oito trimestres o modelo dá 0,095, abaixo dos 0,16 do Banco Central: a calibração não passa nessa conferência."
        , brazil = Just 0.35
        , published = Just ( 0.28, 0.43 )
    }


portfolioResponse : Premise
portfolioResponse =
    startingAt Rest.params.lambda11 Open.portfolioResponse


{-| How far wages follow consumer prices. The book keeps wages fixed.
-}
wageIndexation : Premise
wageIndexation =
    { key = "kappa"
    , name = "Indexação dos salários aos preços"
    , note = "Quanto os salários acompanham os preços ao consumidor: 0 é salário fixo em relação à tendência, como no livro; 1 é reposição integral. A cada trimestre, 21,6% dos salários são reajustados. O valor 1 vem do modelo SAMBA do Banco Central, em que os salários repõem a inflação passada por inteiro. É uma propriedade da estrutura do SAMBA, e não uma estimativa com faixa."
    , lowest = 0
    , highest = 1
    , step = 0.05
    , default = Rest.params.kappa_uk
    , brazil = Just 1
    , published = Nothing
    }


{-| How wages move with unemployment: a wage curve.
-}
wageCurve : Premise
wageCurve =
    { key = "beta"
    , name = "Resposta dos salários ao desemprego"
    , note = "Quanto o salário real cai quando o desemprego sobe 1% acima do nível de partida, de 5,9%. É a chamada curva de salários. O valor −0,06 é de Santolin e Antigo (2020), com dados da PNAD de 2001 a 2015; os mesmos autores citam −0,047 e −0,08 em outros estudos brasileiros, que dão a faixa. 0 desliga a resposta, como no livro."
    , lowest = -0.15
    , highest = 0
    , step = 0.005
    , default = Rest.params.beta_uk
    , brazil = Just -0.06
    , published = Just ( -0.08, -0.047 )
    }


startingAt : Float -> Premise -> Premise
startingAt value premise =
    { premise | default = value }


premises : List Premise
premises =
    [ exportResponse, importResponse, passThrough, portfolioResponse, wageIndexation, wageCurve ]


{-| Premises are anchored on the starting path: each one changes how strongly
the economy reacts when something moves, and none changes where it starts.

A portfolio share, for example, is `lambda10 + lambda11 * r_uk - lambda12 *
(r_us + dxre_us)`. When the reaction `lambda11` changes, `lambda10` is
shifted so that the share at the starting interest rates stays the same.
Trade and import prices are handled the same way.

-}
toParams : Premises -> Policy -> Params
toParams chosen policy =
    let
        rest =
            Rest.params

        at =
            Rest.vars

        portfolio =
            Premise.value portfolioResponse chosen

        exports =
            Premise.value exportResponse chosen

        imports =
            Premise.value importResponse chosen

        pass =
            Premise.value passThrough chosen

        change =
            rest.lambda11 - portfolio

        homeGap =
            rest.r_uk - rest.r_us - rest.dxre_us

        foreignGap =
            rest.r_us - rest.r_uk - rest.dxre_uk
    in
    { rest
        | g_k_uk = policy.spending
        , theta_uk = policy.taxRatePct / 100
        , r_uk = policy.interestRatePct / 100
        , eps1 = exports
        , eps0 = rest.eps0 + (exports - rest.eps1) * logBase e (at.pm_us / at.py_us)
        , mu1 = imports
        , mu0 = rest.mu0 + (imports - rest.mu1) * logBase e (at.pm_uk / at.py_uk)
        , nu1m = pass
        , kappa_uk = Premise.value wageIndexation chosen
        , beta_uk = Premise.value wageCurve chosen
        , nu0m = rest.nu0m - (pass - rest.nu1m) * (logBase e at.py_us - logBase e at.py_uk - logBase e at.xr_uk)
        , lambda10 = rest.lambda10 + change * homeGap
        , lambda20 = rest.lambda20 - change * homeGap
        , lambda40 = rest.lambda40 + change * foreignGap
        , lambda50 = rest.lambda50 - change * foreignGap
        , lambda11 = portfolio
        , lambda12 = portfolio
        , lambda21 = portfolio
        , lambda22 = portfolio
        , lambda41 = portfolio
        , lambda42 = portfolio
        , lambda51 = portfolio
        , lambda52 = portfolio
    }


model : Engine.Model State
model =
    { initial =
        { laggedParams = Rest.params
        , lagged = OpenFlex.carry Rest.params Rest.vars
        , params = Rest.params
        , vars = Rest.vars
        }
    , step = Open.stepWith toParams
    , observe = observe
    }


{-| What the open model shows, plus what wages and unemployment bring: the
real exchange rate first, since nominal values drift once prices do; and
unemployment and inflation. `state.lagged` is last period measured against
this period's trend, so the ratio of the two price levels is the whole
inflation of the period, trend included.
-}
observe : Int -> State -> Snapshot
observe number state =
    let
        base =
            Open.observe number state

        vars =
            state.vars

        real at =
            at.xr_uk * at.pds_uk / at.pds_us

        unemployment =
            100 * vars.u_uk
    in
    { base
        | indicators =
            base.indicators
                ++ [ { name = "Desemprego (%)", value = unemployment }
                   , { name = "Inflação (% ao ano)", value = 100 * ((vars.pds_uk / state.lagged.pds_uk) ^ 4 - 1) }
                   ]
        , charts =
            { name = "Câmbio real (valor da moeda doméstica, corrigido pelos preços dos dois países)", value = real vars / real Rest.vars }
                :: base.charts
                ++ [ { name = "Desemprego (%)", value = unemployment } ]
    }
