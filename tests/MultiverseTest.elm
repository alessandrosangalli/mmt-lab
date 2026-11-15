module MultiverseTest exposing (suite)

import Dict
import Engine exposing (Run, Snapshot)
import Expect
import Model.Open as Open
import Models exposing (ModelId(..))
import Multiverse exposing (Outcome(..))
import Premise exposing (Premise)
import Scenario exposing (Scenario)
import Test exposing (Test, describe, test)


snapshot : Float -> Float -> Snapshot
snapshot income foreignBalance =
    { number = 1
    , income = income
    , householdWealth = 0
    , privateSurplus = 0
    , governmentBalance = 0
    , foreignBalance = foreignBalance
    , indicators = []
    , charts = []
    , flows = []
    , stocks = []
    }


share : Premise
share =
    { key = "share"
    , name = "A share"
    , note = ""
    , lowest = 0
    , highest = 1
    , step = 0.1
    , default = 0.7
    , brazil = Nothing
    , published = Nothing
    }


premiseNamed : String -> Premise
premiseNamed key =
    Open.premises
        |> List.filter (\premise -> premise.key == key)
        |> List.head
        |> Maybe.withDefault share


{-| Government spending raised from 16 to 20 in the open economy.
-}
expansion : Scenario
expansion =
    let
        base =
            Models.defaultScenario OpenModel
    in
    { base
        | initial = { spending = 20, taxRatePct = 20, interestRatePct = 3 }
        , horizon = 120
    }


outcomesAt : Float -> List Outcome
outcomesAt importResponse =
    Multiverse.row (Models.run OpenModel) expansion (premiseNamed "eps1") (premiseNamed "mu1") importResponse
        |> List.map .outcome


suite : Test
suite =
    describe "Multiverse"
        [ test "a run that stops is reported with the period where it stopped" <|
            \_ ->
                Multiverse.classify { snapshots = [ snapshot 100 0 ], failedAt = Just 7 }
                    |> Expect.equal (NoSolution 7)
        , test "a run whose external balance is within a thousandth of income has settled" <|
            \_ ->
                Multiverse.classify { snapshots = [ snapshot 100 5, snapshot 100 -0.09 ], failedAt = Nothing }
                    |> Expect.equal Settles
        , test "a run whose external balance is still open is still adjusting" <|
            \_ ->
                Multiverse.classify { snapshots = [ snapshot 100 0, snapshot 100 0.2 ], failedAt = Nothing }
                    |> Expect.equal StillAdjusting
        , test "a run whose exchange rate has stopped moving has settled, even with the external balance open" <|
            \_ ->
                let
                    at rate =
                        let
                            base =
                                snapshot 100 0.4
                        in
                        { base | charts = [ { name = "rate", value = rate } ] }
                in
                [ Multiverse.classify { snapshots = List.map at (List.repeat 10 0.9 ++ [ 0.895 ]), failedAt = Nothing }
                , Multiverse.classify { snapshots = List.map at (List.repeat 10 0.9 ++ [ 0.88 ]), failedAt = Nothing }
                , Multiverse.classify { snapshots = List.map at [ 0.9, 0.9 ], failedAt = Nothing }
                ]
                    |> Expect.equal [ Settles, StillAdjusting, StillAdjusting ]
        , test "an axis covers the whole range of the premise in even steps" <|
            \_ ->
                Multiverse.axisValues share
                    |> Expect.equal [ 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 ]
        , test "a line varies only the horizontal premise" <|
            \_ ->
                let
                    echo scenario =
                        { snapshots = [ snapshot (Dict.get "share" scenario.premises |> Maybe.withDefault -1) 0 ]
                        , failedAt =
                            if Dict.get "other" scenario.premises == Just 0.4 then
                                Nothing

                            else
                                Just 1
                        }
                in
                Multiverse.row echo Scenario.default share { share | key = "other" } 0.4
                    |> List.map (\cell -> ( cell.x, cell.y, cell.outcome ))
                    |> Expect.equal (List.map (\x -> ( x, 0.4, Settles )) (Multiverse.axisValues share))
        , test "with imports fully responsive to price, the open economy settles whatever the export response" <|
            \_ ->
                outcomesAt 1
                    |> Expect.equal (List.repeat 11 Settles)
        , test "with imports half responsive, the outcome depends on exports exactly as in the prototype" <|
            \_ ->
                outcomesAt 0.5
                    |> Expect.equal
                        [ NoSolution 62
                        , NoSolution 67
                        , NoSolution 75
                        , NoSolution 88
                        , NoSolution 111
                        , StillAdjusting
                        , StillAdjusting
                        , Settles
                        , Settles
                        , Settles
                        , Settles
                        ]
        , test "with imports unresponsive, the open economy never settles" <|
            \_ ->
                outcomesAt 0
                    |> Expect.equal
                        (List.map NoSolution [ 33, 34, 35, 36, 37, 39, 41, 43, 46, 49, 54 ])
        ]
