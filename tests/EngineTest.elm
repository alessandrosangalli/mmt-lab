module EngineTest exposing (suite)

import Engine exposing (Snapshot)
import Expect exposing (FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer)
import Model.Pc as Pc
import Models exposing (ModelId(..))
import Policy exposing (Policy)
import Scenario exposing (Scenario)
import Sfc.Matrix as Matrix
import Test exposing (Test, describe, fuzz2, test)


{-| Policies inside the range where both models stay well behaved.
-}
policyFuzzer : Fuzzer Policy
policyFuzzer =
    Fuzz.map3 Policy
        (Fuzz.floatRange 1 50)
        (Fuzz.floatRange 10 40)
        (Fuzz.floatRange 0 5)


{-| A scenario with one change of policy somewhere in the middle.
-}
scenarioFuzzer : Fuzzer Scenario
scenarioFuzzer =
    Fuzz.map3
        (\initial changed period ->
            { initial = initial
            , changes = [ { period = period, policy = changed } ]
            , horizon = 40
            }
        )
        policyFuzzer
        policyFuzzer
        (Fuzz.intRange 2 40)


modelFuzzer : Fuzzer ModelId
modelFuzzer =
    Fuzz.oneOfValues Models.all


everySnapshot : (Snapshot -> Bool) -> ModelId -> Scenario -> Expect.Expectation
everySnapshot holds model scenario =
    Models.run model scenario
        |> List.all holds
        |> Expect.equal True


closeToZero : Float -> Float -> Bool
closeToZero scale value =
    abs value <= 1.0e-9 * max 1 (abs scale)


suite : Test
suite =
    describe "Engine"
        [ fuzz2 modelFuzzer scenarioFuzzer "every period's transactions balance, in every model" <|
            \model scenario ->
                everySnapshot
                    (\snapshot -> Matrix.isBalanced (Models.info model).sectors snapshot.flows)
                    model
                    scenario
        , fuzz2 modelFuzzer scenarioFuzzer "every balance sheet stays inside the model's sectors" <|
            \model scenario ->
                let
                    sectors =
                        (Models.info model).sectors

                    inside claim =
                        List.member claim.from sectors && List.member claim.to sectors
                in
                everySnapshot (\snapshot -> List.all inside snapshot.stocks) model scenario
        , fuzz2 modelFuzzer scenarioFuzzer "the private surplus mirrors the government balance, in every model" <|
            \model scenario ->
                everySnapshot
                    (\snapshot -> closeToZero snapshot.income (snapshot.privateSurplus + snapshot.governmentBalance))
                    model
                    scenario
        , fuzz2 modelFuzzer scenarioFuzzer "household wealth is the sum of the private surpluses so far" <|
            \model scenario ->
                let
                    snapshots =
                        Models.run model scenario

                    accumulated =
                        List.sum (List.map .privateSurplus snapshots)
                in
                case List.head (List.reverse snapshots) of
                    Just latest ->
                        Expect.within (AbsoluteOrRelative 1.0e-6 1.0e-9) accumulated latest.householdWealth

                    Nothing ->
                        Expect.fail "no periods"
        , test "the engine reproduces model PC stepped by hand" <|
            \_ ->
                Models.run PcModel Scenario.default
                    |> List.map .income
                    |> Expect.equal
                        (Pc.advanceBy Scenario.default.horizon Pc.bookBehaviour Scenario.default.initial []
                            |> List.reverse
                            |> List.map (\period -> period.outcome.income)
                        )
        , test "a version string names its model" <|
            \_ ->
                List.map Models.fromVersion [ "sim-1", "pc-1", "pc-7", "other-1", "" ]
                    |> Expect.equal [ Just SimModel, Just PcModel, Just PcModel, Nothing, Nothing ]
        , test "every model's current version names itself" <|
            \_ ->
                List.map (\model -> Models.fromVersion (Models.info model).version) Models.all
                    |> Expect.equal (List.map Just Models.all)
        ]
