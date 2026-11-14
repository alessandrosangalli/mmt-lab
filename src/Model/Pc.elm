module Model.Pc exposing
    ( Behaviour
    , Outcome
    , Period
    , Policy
    , State
    , SteadyState
    , advance
    , advanceBy
    , bookBehaviour
    , flows
    , initial
    , sectors
    , steadyState
    , step
    )

{-| Model PC from Godley and Lavoie, "Monetary Economics" (2007), chapter 4.

It adds government bills, a central bank and an interest rate to model SIM.
Households split their wealth between money and bills (the "portfolio
choice" that names the model), the central bank buys whatever bills the
households do not want, and the interest rate is whatever the central bank
decides.

The equations follow the replication in the `sfcr` R package, and the
steady state follows the closed form documented by the `macrostat` Python
package. Within a period nothing is simultaneous, so no solver is needed.

-}

import Sfc.Matrix exposing (Flow, Sector(..))



-- TYPES


{-| What the government and the central bank decide.
-}
type alias Policy =
    { spending : Float
    , taxRatePct : Float
    , interestRatePct : Float
    }


{-| How households behave: how much they consume out of income and out of
wealth, and how they split wealth between bills and money.
-}
type alias Behaviour =
    { alpha1 : Float
    , alpha2 : Float
    , lambda0 : Float
    , lambda1 : Float
    , lambda2 : Float
    }


{-| The values used in the book's baseline, with the interest rate as a
fraction (0.025 for 2.5%).

`lambda1` is 5 here. The `sfcr` vignette uses 0.05 with the same fractional
rate, which makes the interest rate almost irrelevant to the portfolio. The
value 5 is the one that gives a steady-state income of 106.49 at a 2.5% rate.

With these values the bill share of wealth passes 100% once the rate goes
above roughly 7%, so they are not usable at Brazilian interest rates.

-}
bookBehaviour : Behaviour
bookBehaviour =
    { alpha1 = 0.6
    , alpha2 = 0.4
    , lambda0 = 0.635
    , lambda1 = 5
    , lambda2 = 0.01
    }


{-| The stocks at the end of a period, and the interest rate set in it,
which is the rate paid on bills during the next period.
-}
type alias State =
    { wealth : Float
    , householdBills : Float
    , householdMoney : Float
    , billsIssued : Float
    , centralBankBills : Float
    , moneyIssued : Float
    , interestRate : Float
    }


initial : State
initial =
    { wealth = 0
    , householdBills = 0
    , householdMoney = 0
    , billsIssued = 0
    , centralBankBills = 0
    , moneyIssued = 0
    , interestRate = 0
    }


{-| Everything that happens within one period.
-}
type alias Outcome =
    { income : Float
    , consumption : Float
    , spending : Float
    , taxes : Float
    , disposableIncome : Float
    , householdInterest : Float
    , centralBankInterest : Float
    , moneyChange : Float
    , householdBillsChange : Float
    , centralBankBillsChange : Float
    }


type alias Period =
    { number : Int
    , state : State
    , outcome : Outcome
    }



-- MODEL


{- The equations, with (-1) marking the previous period's value:

   Y   = C + G
   YD  = Y - T + r(-1) * Bh(-1)
   T   = theta * (Y + r(-1) * Bh(-1))
   C   = a1 * YD + a2 * V(-1)
   V   = V(-1) + YD - C
   Bh  = V * (l0 + l1 * r - l2 * YD / V)
   Hh  = V - Bh
   Bs  = Bs(-1) + (G + r(-1) * Bs(-1)) - (T + r(-1) * Bcb(-1))
   Bcb = Bs - Bh
   Hs  = Hs(-1) + Bcb - Bcb(-1)
-}


{-| One period of the economy.

The model never states that the money issued equals the money households
hold. It follows from the accounting, and the tests check it.

-}
step : Behaviour -> Policy -> State -> ( Outcome, State )
step behaviour policy previous =
    let
        theta =
            policy.taxRatePct / 100

        rate =
            policy.interestRatePct / 100

        householdInterest =
            previous.interestRate * previous.householdBills

        centralBankInterest =
            previous.interestRate * previous.centralBankBills

        kept =
            behaviour.alpha1 * (1 - theta)

        income =
            (kept * householdInterest + behaviour.alpha2 * previous.wealth + policy.spending)
                / (1 - kept)

        taxes =
            theta * (income + householdInterest)

        disposableIncome =
            income - taxes + householdInterest

        consumption =
            behaviour.alpha1 * disposableIncome + behaviour.alpha2 * previous.wealth

        wealth =
            previous.wealth + disposableIncome - consumption

        householdBills =
            (behaviour.lambda0 + behaviour.lambda1 * rate) * wealth - behaviour.lambda2 * disposableIncome

        householdMoney =
            wealth - householdBills

        billsIssued =
            previous.billsIssued
                + (policy.spending + previous.interestRate * previous.billsIssued)
                - (taxes + centralBankInterest)

        centralBankBills =
            billsIssued - householdBills

        moneyIssued =
            previous.moneyIssued + centralBankBills - previous.centralBankBills
    in
    ( { income = income
      , consumption = consumption
      , spending = policy.spending
      , taxes = taxes
      , disposableIncome = disposableIncome
      , householdInterest = householdInterest
      , centralBankInterest = centralBankInterest
      , moneyChange = householdMoney - previous.householdMoney
      , householdBillsChange = householdBills - previous.householdBills
      , centralBankBillsChange = centralBankBills - previous.centralBankBills
      }
    , { wealth = wealth
      , householdBills = householdBills
      , householdMoney = householdMoney
      , billsIssued = billsIssued
      , centralBankBills = centralBankBills
      , moneyIssued = moneyIssued
      , interestRate = rate
      }
    )


{-| Add one period to a history whose most recent period comes first.
-}
advance : Behaviour -> Policy -> List Period -> List Period
advance behaviour policy history =
    let
        ( previousNumber, previousState ) =
            case history of
                latest :: _ ->
                    ( latest.number, latest.state )

                [] ->
                    ( 0, initial )

        ( outcome, state ) =
            step behaviour policy previousState
    in
    { number = previousNumber + 1
    , state = state
    , outcome = outcome
    }
        :: history


advanceBy : Int -> Behaviour -> Policy -> List Period -> List Period
advanceBy count behaviour policy history =
    if count <= 0 then
        history

    else
        advanceBy (count - 1) behaviour policy (advance behaviour policy history)



-- STEADY STATE


type alias SteadyState =
    { income : Float
    , disposableIncome : Float
    , wealth : Float
    , householdBills : Float
    }


{-| Where the economy settles under a constant policy, in closed form.

In the steady state wealth stops changing, so consumption equals disposable
income, and both the wealth and the bills households hold are fixed
multiples of that income.

-}
steadyState : Behaviour -> Policy -> SteadyState
steadyState behaviour policy =
    let
        theta =
            policy.taxRatePct / 100

        rate =
            policy.interestRatePct / 100

        wealthToIncome =
            (1 - behaviour.alpha1) / behaviour.alpha2

        billsToIncome =
            (behaviour.lambda0 + behaviour.lambda1 * rate) * wealthToIncome - behaviour.lambda2

        disposableIncome =
            policy.spending / (theta / (1 - theta) - rate * billsToIncome)
    in
    { income = disposableIncome + policy.spending
    , disposableIncome = disposableIncome
    , wealth = wealthToIncome * disposableIncome
    , householdBills = billsToIncome * disposableIncome
    }



-- TRANSACTION FLOWS


sectors : List Sector
sectors =
    [ Households, Firms, Government, CentralBank ]


{-| The period's payments. The last three are the changes in the stocks:
households acquiring money from the central bank, and households and the
central bank acquiring bills from the government.
-}
flows : Outcome -> List Flow
flows outcome =
    [ Flow "Consumo" Households Firms outcome.consumption
    , Flow "Gasto público" Government Firms outcome.spending
    , Flow "Salários" Firms Households outcome.income
    , Flow "Juros dos títulos das famílias" Government Households outcome.householdInterest
    , Flow "Juros dos títulos do banco central" Government CentralBank outcome.centralBankInterest
    , Flow "Lucro do banco central" CentralBank Government outcome.centralBankInterest
    , Flow "Impostos" Households Government outcome.taxes
    , Flow "Variação do dinheiro" Households CentralBank outcome.moneyChange
    , Flow "Variação dos títulos das famílias" Households Government outcome.householdBillsChange
    , Flow "Variação dos títulos do banco central" CentralBank Government outcome.centralBankBillsChange
    ]
