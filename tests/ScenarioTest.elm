module ScenarioTest exposing (suite)

import Expect exposing (FloatingPointTolerance(..))
import Fuzz
import Model.Sim as Sim
import Scenario exposing (Scenario)
import Test exposing (Test, describe, fuzz, test)


stimulus : Scenario
stimulus =
    { initial = { spending = 20, taxRatePct = 20 }
    , changes = [ { period = 60, policy = { spending = 30, taxRatePct = 20 } } ]
    , horizon = 120
    }


incomeAt : Int -> Scenario -> Maybe Float
incomeAt period scenario =
    Scenario.run scenario
        |> List.drop (period - 1)
        |> List.head
        |> Maybe.map (\found -> found.outcome.income)


suite : Test
suite =
    describe "Scenario"
        [ fuzz (Fuzz.intRange Scenario.minHorizon Scenario.maxHorizon) "runs exactly as many periods as the horizon" <|
            \horizon ->
                let
                    base =
                        Scenario.default
                in
                Scenario.run { base | horizon = horizon }
                    |> List.length
                    |> Expect.equal horizon
        , test "without changes it matches stepping the model directly" <|
            \_ ->
                Scenario.run Scenario.default
                    |> Expect.equal (List.reverse (Sim.advanceBy Scenario.default.horizon Scenario.default.initial []))
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
                                [ { period = 10, policy = { spending = 1, taxRatePct = 20 } }
                                , { period = 10, policy = { spending = 2, taxRatePct = 20 } }
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
                                [ { period = 30, policy = { spending = 3, taxRatePct = 20 } }
                                , { period = 10, policy = { spending = 1, taxRatePct = 20 } }
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
                    { initial = { spending = 999, taxRatePct = 0 }
                    , changes = [ { period = -4, policy = { spending = -1, taxRatePct = 80 } } ]
                    , horizon = 100000
                    }
                    |> Expect.equal
                        { initial = { spending = 50, taxRatePct = 5 }
                        , changes = [ { period = 2, policy = { spending = 0, taxRatePct = 50 } } ]
                        , horizon = Scenario.maxHorizon
                        }
        ]
