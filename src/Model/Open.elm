module Model.Open exposing (State, defaultPolicy, model, premises, sectors)

{-| Model OPENFLEX as the laboratory shows it: the home country, in its own
currency, with the other country as the rest of the world.

The laboratory's policy drives the home country only: its real government
spending, its tax rate and its interest rate. The other country keeps the
book's baseline throughout.

-}

import Engine exposing (Snapshot)
import Model.OpenFlex as OpenFlex exposing (Params, Vars)
import Policy exposing (Policy)
import Premise exposing (Premise, Premises)
import Sfc.Matrix exposing (Flow, Sector(..))


{-| The period just solved and the one before it. Both are needed to tell
payments from holdings: a payment is a change in a holding.
-}
type alias State =
    { laggedParams : Params
    , lagged : Vars
    , params : Params
    , vars : Vars
    }


sectors : List Sector
sectors =
    OpenFlex.sectors


{-| The policy under which the economy starts at rest.
-}
defaultPolicy : Policy
defaultPolicy =
    { spending = OpenFlex.bookParams.g_k_uk
    , taxRatePct = OpenFlex.bookParams.theta_uk * 100
    , interestRatePct = OpenFlex.bookParams.r_uk * 100
    }


exportResponse : Premise
exportResponse =
    { key = "eps1"
    , name = "Resposta das exportações ao câmbio"
    , note = "Quanto as exportações crescem quando a moeda perde valor. O livro usa 0,70. Para o Brasil, Schettini, Squeff e Gouvêa (2012) estimam cerca de 0,01, entre −0,04 e 0,11."
    , lowest = 0
    , highest = 1
    , step = 0.01
    , default = OpenFlex.bookParams.eps1
    }


importResponse : Premise
importResponse =
    { key = "mu1"
    , name = "Resposta das importações ao preço"
    , note = "Quanto as importações caem quando ficam mais caras. O livro usa 0,70. Este projeto ainda não conferiu nenhuma estimativa brasileira."
    , lowest = 0
    , highest = 1
    , step = 0.05
    , default = OpenFlex.bookParams.mu1
    }


passThrough : Premise
passThrough =
    { key = "nu1m"
    , name = "Repasse do câmbio aos preços de importação"
    , note = "Que parte de uma queda da moeda chega aos preços dos importados. O livro usa 0,70. A medida brasileira disponível é o efeito final no IPCA: de 0,10 a 0,16 em um a dois anos (Banco Central, 2026)."
    , lowest = 0
    , highest = 1
    , step = 0.05
    , default = OpenFlex.bookParams.nu1m
    }


portfolioResponse : Premise
portfolioResponse =
    { key = "port"
    , name = "Reação das carteiras aos juros"
    , note = "Quantos pontos da riqueza trocam de título a cada ponto de diferença entre os juros dos dois países. O livro usa 5. Não há estimativa brasileira: é a maior lacuna da calibração."
    , lowest = 0
    , highest = 10
    , step = 0.5
    , default = OpenFlex.bookParams.lambda11
    }


{-| The assumptions of this model that are disputed for Brazil. None of them
moves the starting point: under the default policy the economy stays at rest
whatever their values.
-}
premises : List Premise
premises =
    [ exportResponse, importResponse, passThrough, portfolioResponse ]


toParams : Premises -> Policy -> Params
toParams chosen policy =
    let
        book =
            OpenFlex.bookParams

        portfolio =
            Premise.value portfolioResponse chosen
    in
    { book
        | g_k_uk = policy.spending
        , theta_uk = policy.taxRatePct / 100
        , r_uk = policy.interestRatePct / 100
        , eps1 = Premise.value exportResponse chosen
        , mu1 = Premise.value importResponse chosen
        , nu1m = Premise.value passThrough chosen
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
        { laggedParams = OpenFlex.bookParams
        , lagged = OpenFlex.steadyState
        , params = OpenFlex.bookParams
        , vars = OpenFlex.steadyState
        }
    , step = step
    , observe = observe
    }


step : Premises -> Policy -> State -> Maybe State
step chosen policy state =
    let
        params =
            toParams chosen policy

        advance vars =
            { laggedParams = state.params
            , lagged = state.vars
            , params = params
            , vars = vars
            }
    in
    OpenFlex.step state.params state.vars params
        |> Result.toMaybe
        |> Maybe.map advance


observe : Int -> State -> Snapshot
observe number state =
    let
        vars =
            state.vars

        lagged =
            state.lagged

        interestReceived =
            (state.laggedParams.r_uk * lagged.b_ukuk_d)
                + (vars.xr_us * state.laggedParams.r_us * lagged.b_ukus_s)
    in
    { number = number
    , income = vars.y_k_uk
    , householdWealth = vars.v_uk
    , privateSurplus = vars.y_uk + interestReceived - vars.t_uk - vars.cons_uk
    , governmentBalance = negate vars.psbr_uk
    , foreignBalance = negate vars.cab_uk
    , indicators =
        [ { name = "PIB real", value = vars.y_k_uk }
        , { name = "Taxa de câmbio", value = vars.xr_uk }
        , { name = "Nível de preços", value = vars.pds_uk }
        , { name = "Déficit do governo", value = vars.psbr_uk }
        , { name = "Conta corrente", value = vars.cab_uk }
        , { name = "Exportações", value = vars.x_uk }
        , { name = "Importações", value = vars.im_uk }
        , { name = "Riqueza das famílias", value = vars.v_uk }
        ]
    , charts =
        [ { name = "Taxa de câmbio (valor da moeda doméstica)", value = vars.xr_uk }
        , { name = "Nível de preços doméstico", value = vars.pds_uk }
        ]
    , flows = OpenFlex.flows state.laggedParams lagged state.params vars
    , stocks =
        [ Flow "Dinheiro" CentralBank Households vars.h_uk_d
        , Flow "Títulos domésticos das famílias" Government Households vars.b_ukuk_d
        , Flow "Títulos domésticos do banco central" Government CentralBank vars.b_cb_ukuk_d
        , Flow "Títulos domésticos do exterior" Government RestOfWorld vars.b_usuk_s
        , Flow "Títulos estrangeiros das famílias" RestOfWorld Households vars.b_ukus_d
        , Flow "Reservas do banco central" RestOfWorld CentralBank (state.params.b_cb_ukus_s * vars.xr_us)
        ]
    }
