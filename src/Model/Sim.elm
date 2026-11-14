module Model.Sim exposing
    ( Outcome
    , Period
    , State
    , advance
    , advanceBy
    , flows
    , model
    , sectors
    , steadyStateIncome
    , step
    , taxRate
    )

{-| Model SIM from Godley and Lavoie, "Monetary Economics" (2007), chapter 3.

Three sectors (households, firms and government) and a single asset: the
money the government issues when it spends.

-}

import Engine exposing (Snapshot)
import Policy exposing (Policy)
import Sfc.Matrix exposing (Flow, Sector(..))



-- HOUSEHOLD BEHAVIOUR (fixed for now)


{-| Share of disposable income that households spend each period.
-}
propensityOutOfIncome : Float
propensityOutOfIncome =
    0.6


{-| Share of their money holdings that households spend each period.
-}
propensityOutOfWealth : Float
propensityOutOfWealth =
    0.4



-- TYPES


{-| Everything that happens within one period.
-}
type alias Outcome =
    { income : Float
    , consumption : Float
    , spending : Float
    , taxes : Float
    , disposableIncome : Float
    , moneyChange : Float
    }


type alias Period =
    { number : Int
    , money : Float
    , outcome : Outcome
    }



-- MODEL


taxRate : Policy -> Float
taxRate policy =
    policy.taxRatePct / 100


{-| One period of the economy.

    Y  = C + G                       (income is everything that is spent)
    T  = theta * Y                   (taxes on income)
    YD = Y - T                       (disposable income)
    C  = a1 * YD + a2 * H(previous)  (consumption)
    dH = YD - C  =  G - T            (the deficit becomes household money)

Substituting C into the first equation gives income directly:
Y = (G + a2 \* H) / (1 - a1 \* (1 - theta))

-}
step : Policy -> Float -> Outcome
step policy previousMoney =
    let
        theta =
            taxRate policy

        income =
            (policy.spending + propensityOutOfWealth * previousMoney)
                / (1 - propensityOutOfIncome * (1 - theta))

        taxes =
            theta * income

        disposableIncome =
            income - taxes

        consumption =
            propensityOutOfIncome * disposableIncome + propensityOutOfWealth * previousMoney
    in
    { income = income
    , consumption = consumption
    , spending = policy.spending
    , taxes = taxes
    , disposableIncome = disposableIncome
    , moneyChange = disposableIncome - consumption
    }


{-| Add one period to a history whose most recent period comes first.
-}
advance : Policy -> List Period -> List Period
advance policy history =
    let
        ( previousNumber, previousMoney ) =
            case history of
                latest :: _ ->
                    ( latest.number, latest.money )

                [] ->
                    ( 0, 0 )

        outcome =
            step policy previousMoney
    in
    { number = previousNumber + 1
    , money = previousMoney + outcome.moneyChange
    , outcome = outcome
    }
        :: history


advanceBy : Int -> Policy -> List Period -> List Period
advanceBy count policy history =
    if count <= 0 then
        history

    else
        advanceBy (count - 1) policy (advance policy history)


{-| Where the economy settles: the deficit vanishes when T = G, that is,
when theta \* Y = G.
-}
steadyStateIncome : Policy -> Float
steadyStateIncome policy =
    policy.spending / taxRate policy



-- TRANSACTION FLOWS


sectors : List Sector
sectors =
    [ Households, Firms, Government ]


{-| The period's payments. The last one is the households acquiring the newly
issued money, which is how the change in the stock enters the matrix.
-}
flows : Outcome -> List Flow
flows outcome =
    [ Flow "Consumo" Households Firms outcome.consumption
    , Flow "Gasto público" Government Firms outcome.spending
    , Flow "Salários" Firms Households outcome.income
    , Flow "Impostos" Households Government outcome.taxes
    , Flow "Variação do dinheiro" Households Government outcome.moneyChange
    ]



-- ENGINE


{-| What the engine carries from one period to the next: the money households
hold, and what happened in the period that just ended.
-}
type alias State =
    { money : Float
    , outcome : Outcome
    }


model : Engine.Model State
model =
    { initial =
        { money = 0
        , outcome =
            { income = 0
            , consumption = 0
            , spending = 0
            , taxes = 0
            , disposableIncome = 0
            , moneyChange = 0
            }
        }
    , step = stepState
    , observe = observe
    }


stepState : Policy -> State -> Maybe State
stepState policy state =
    let
        outcome =
            step policy state.money
    in
    Just
        { money = state.money + outcome.moneyChange
        , outcome = outcome
        }


observe : Int -> State -> Snapshot
observe number state =
    { number = number
    , income = state.outcome.income
    , householdWealth = state.money
    , privateSurplus = state.outcome.disposableIncome - state.outcome.consumption
    , governmentBalance = state.outcome.taxes - state.outcome.spending
    , foreignBalance = 0
    , indicators =
        [ { name = "PIB", value = state.outcome.income }
        , { name = "Déficit do governo", value = state.outcome.spending - state.outcome.taxes }
        , { name = "Dinheiro das famílias", value = state.money }
        ]
    , charts = []
    , flows = flows state.outcome
    , stocks = [ Flow "Dinheiro" Government Households state.money ]
    }
