module ScenarioTest exposing (suite)

import Engine
import Expect exposing (FloatingPointTolerance(..))
import Fuzz
import Model.Sim as Sim
import Policy exposing (Policy)
import Scenario exposing (Scenario)
import Test exposing (Test, describe, fuzz, test)


policy : Float -> Policy
policy spending =
    { spending = spending, taxRatePct = 20, interestRatePct = 2.5 }


stimulus : Scenario
stimulus =
    { initial = policy 20
    , changes = [ { period = 60, policy = policy 30 } ]
    , horizon = 120
    }


incomeAt : Int -> Scenario -> Maybe Float
incomeAt period scenario =
    Engine.run Sim.model scenario
        |> List.drop (period - 1)
        |> List.head
        |> Maybe.map .income


suite : Test
suite =
    describe "Scenario"
        [ fuzz (Fuzz.intRange Scenario.minHorizon Scenario.maxHorizon) "runs exactly as many periods as the horizon" <|
            \horizon ->
                let
                    base =
                        Scenario.default
                in
                Engine.run Sim.model { base | horizon = horizon }
                    |> List.length
                    |> Expect.equal horizon
        , test "without changes it matches stepping the model directly" <|
            \_ ->
                Engine.run Sim.model Scenario.default
                    |> List.map .income
                    |> Expect.equal
                        (Sim.advanceBy Scenario.default.horizon Scenario.default.initial []
                            |> List.reverse
                            |> List.map (\period -> period.outcome.income)
                        )
        , test "the initial policy holds until the change" <|
            \_ ->
                Scenario.policyAt stimulus 59
                    |> Expect.equal stimulus.initial
        , test "the new policy holds from the change on" <|
            \_ ->
                List.map (\period -> (Scenario.policyAt stimulus period).spending) [ 60, 61, 120 ]
                    |> Expect.equal [ 30, 30, 30 ]
        , test "when two changes share a period, the later one wins" <|
            \_ ->
                let
                    scenario =
                        { stimulus
                            | changes =
                                [ { period = 10, policy = policy 1 }
                                , { period = 10, policy = policy 2 }
                                ]
                        }
                in
                (Scenario.policyAt scenario 10).spending
                    |> Expect.equal 2
        , test "changes apply in period order, whatever their order in the list" <|
            \_ ->
                let
                    scenario =
                        { stimulus
                            | changes =
                                [ { period = 30, policy = policy 3 }
                                , { period = 10, policy = policy 1 }
                                ]
                        }
                in
                List.map (\period -> (Scenario.policyAt scenario period).spending) [ 9, 10, 29, 30 ]
                    |> Expect.equal [ 20, 1, 1, 3 ]
        , test "income settles at the old steady state before the change" <|
            \_ ->
                incomeAt 59 stimulus
                    |> Maybe.withDefault 0
                    |> Expect.within (Absolute 0.05) 100
        , test "income moves to the new steady state after the change" <|
            \_ ->
                incomeAt 120 stimulus
                    |> Maybe.withDefault 0
                    |> Expect.within (Absolute 0.05) 150
        , test "sanitize brings every value into range" <|
            \_ ->
                Scenario.sanitize
                    { initial = { spending = 999, taxRatePct = 0, interestRatePct = 40 }
                    , changes = [ { period = -4, policy = { spending = -1, taxRatePct = 80, interestRatePct = -2 } } ]
                    , horizon = 100000
                    }
                    |> Expect.equal
                        { initial = { spending = 50, taxRatePct = 5, interestRatePct = 6 }
                        , changes = [ { period = 2, policy = { spending = 0, taxRatePct = 50, interestRatePct = 0 } } ]
                        , horizon = Scenario.maxHorizon
                        }
        , test "addChange appends a change ten periods after the latest" <|
            \_ ->
                (Scenario.addChange stimulus).changes
                    |> List.map .period
                    |> Expect.equal [ 60, 70 ]
        , test "addChange stops when the list is full" <|
            \_ ->
                List.foldl (\_ scenario -> Scenario.addChange scenario) Scenario.default (List.range 1 20)
                    |> .changes
                    |> List.length
                    |> Expect.equal Scenario.maxChanges
        , test "updateChange edits only the change at the index" <|
            \_ ->
                Scenario.addChange stimulus
                    |> Scenario.updateChange 1 (\change -> { change | period = 99 })
                    |> .changes
                    |> List.map .period
                    |> Expect.equal [ 60, 99 ]
        , test "removeChange drops only the change at the index" <|
            \_ ->
                Scenario.addChange stimulus
                    |> Scenario.removeChange 0
                    |> .changes
                    |> List.map .period
                    |> Expect.equal [ 70 ]
        ]
