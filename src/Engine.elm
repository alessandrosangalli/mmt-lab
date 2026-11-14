module Engine exposing (Indicator, Model, Snapshot, run)

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

`flows` are the period's payments. `stocks` are the claims outstanding at
the end of the period, each written as a flow from the debtor to the holder,
so the balance sheet is built the same way as the transactions matrix.

-}
type alias Snapshot =
    { number : Int
    , income : Float
    , householdWealth : Float
    , privateSurplus : Float
    , governmentBalance : Float
    , indicators : List Indicator
    , flows : List Flow
    , stocks : List Flow
    }


type alias Model state =
    { initial : state
    , step : Policy -> state -> state
    , observe : Int -> state -> Snapshot
    }


{-| Every period of the scenario, oldest first.
-}
run : Model state -> Scenario -> List Snapshot
run model scenario =
    let
        advance period ( state, snapshots ) =
            let
                next =
                    model.step (Scenario.policyAt scenario period) state
            in
            ( next, model.observe period next :: snapshots )
    in
    List.range 1 scenario.horizon
        |> List.foldl advance ( model.initial, [] )
        |> Tuple.second
        |> List.reverse
