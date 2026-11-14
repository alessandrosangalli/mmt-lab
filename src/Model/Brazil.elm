module Model.Brazil exposing (defaultPolicy, model, premises, sectors)

{-| Model OPENFLEX started from a growth path with Brazilian proportions,
with the period read as a quarter.

The equations are the book's, plus government transfers and trend growth.
What changes is where the economy starts (`Model.BrazilRest`) and the default
value of each premise, which is the Brazilian one where this project has
read a source. Every value is measured relative to its trend.

-}

import Engine
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


passThrough : Premise
passThrough =
    startingAt Rest.params.nu1m Open.passThrough


portfolioResponse : Premise
portfolioResponse =
    startingAt Rest.params.lambda11 Open.portfolioResponse


startingAt : Float -> Premise -> Premise
startingAt value premise =
    { premise | default = value }


premises : List Premise
premises =
    [ exportResponse, importResponse, passThrough, portfolioResponse ]


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
    , observe = Open.observe
    }
