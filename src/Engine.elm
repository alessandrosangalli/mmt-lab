module Engine exposing (Indicator, Model, Run, Snapshot, run)

{-| The interface every model implements, and the loop that runs a scenario
through it.

A model is a starting state, a pure step from one state to the next, and a
way to describe a state in terms the screen understands. The screen only
ever sees snapshots, so adding a model does not change the screen.

-}

import Policy exposing (Policy)
import Scenario exposing (Scenario)
import Sfc.Matrix exposing (Flow)


type alias Indicator =
    { name : String
    , value : Float
    }


{-| One period as the screen sees it, whatever the model.

The three balances are what each sector saved in the period: households and
firms together, the government, and the rest of the world. They add up to
zero. A closed model has a foreign balance of zero.

`charts` are further series worth drawing over time, such as the exchange
rate. `flows` are the period's payments. `stocks` are the claims outstanding
at the end of the period, each written as a flow from the debtor to the
holder, so the balance sheet is built the same way as the transactions
matrix.

-}
type alias Snapshot =
    { number : Int
    , income : Float
    , householdWealth : Float
    , privateSurplus : Float
    , governmentBalance : Float
    , foreignBalance : Float
    , indicators : List Indicator
    , charts : List Indicator
    , flows : List Flow
    , stocks : List Flow
    }


{-| `step` gives `Nothing` when the model has no solution for the period.
-}
type alias Model state =
    { initial : state
    , step : Policy -> state -> Maybe state
    , observe : Int -> state -> Snapshot
    }


{-| The periods that could be solved, oldest first, and the period where the
model stopped having a solution, if it did.
-}
type alias Run =
    { snapshots : List Snapshot
    , failedAt : Maybe Int
    }


run : Model state -> Scenario -> Run
run model scenario =
    advance model scenario 1 model.initial []


advance : Model state -> Scenario -> Int -> state -> List Snapshot -> Run
advance model scenario period state snapshots =
    if period > scenario.horizon then
        { snapshots = List.reverse snapshots, failedAt = Nothing }

    else
        case model.step (Scenario.policyAt scenario period) state of
            Just next ->
                advance model scenario (period + 1) next (model.observe period next :: snapshots)

            Nothing ->
                { snapshots = List.reverse snapshots, failedAt = Just period }
