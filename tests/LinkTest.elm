module LinkTest exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Link
import Models exposing (ModelId(..))
import Policy exposing (Policy)
import Scenario exposing (Change, Scenario)
import Test exposing (Test, describe, fuzz3, test)


policyFuzzer : Fuzzer Policy
policyFuzzer =
    Fuzz.map3 Policy
        (Fuzz.floatRange 0 50)
        (Fuzz.floatRange 5 50)
        (Fuzz.floatRange 0 6)


changeFuzzer : Fuzzer Change
changeFuzzer =
    Fuzz.map2 Change
        (Fuzz.intRange 2 Scenario.maxHorizon)
        policyFuzzer


{-| Any scenario that is already within the accepted ranges.
-}
scenarioFuzzer : Fuzzer Scenario
scenarioFuzzer =
    Fuzz.map3 Scenario
        policyFuzzer
        (Fuzz.listOfLengthBetween 0 Scenario.maxChanges changeFuzzer)
        (Fuzz.intRange Scenario.minHorizon Scenario.maxHorizon)


{-| A scenario with an optional second one on the same time axis.
-}
pairFuzzer : Fuzzer ( Scenario, Maybe Scenario )
pairFuzzer =
    Fuzz.map2
        (\scenario other -> ( scenario, Maybe.map (\found -> { found | horizon = scenario.horizon }) other ))
        scenarioFuzzer
        (Fuzz.maybe scenarioFuzzer)


modelFuzzer : Fuzzer ModelId
modelFuzzer =
    Fuzz.oneOfValues Models.all


suite : Test
suite =
    describe "Link"
        [ fuzz3 modelFuzzer pairFuzzer (Fuzz.intRange 1 Scenario.minHorizon) "a model and its scenarios survive the round trip through a link" <|
            \model ( scenario, comparison ) selected ->
                Link.fromQuery (Link.toQuery model scenario comparison selected)
                    |> Expect.equal
                        { model = model
                        , scenario = scenario
                        , comparison = comparison
                        , selected = selected
                        , version = Just (Models.info model).version
                        }
        , test "an empty query gives the default scenario on the simplest model" <|
            \_ ->
                Link.fromQuery ""
                    |> Expect.equal
                        { model = SimModel
                        , scenario = Scenario.default
                        , comparison = Nothing
                        , selected = Scenario.default.horizon
                        , version = Nothing
                        }
        , test "a leading question mark is accepted" <|
            \_ ->
                (Link.fromQuery "?g=30").scenario.initial.spending
                    |> Expect.equal 30
        , test "garbage falls back to defaults and stays in range" <|
            \_ ->
                Link.fromQuery "?g=abc&t=&n=-3&c=1:2,xx,7:8:9:10:11&p=999&junk"
                    |> Expect.equal
                        { model = SimModel
                        , scenario =
                            { initial = Scenario.default.initial
                            , changes = []
                            , horizon = Scenario.minHorizon
                            }
                        , comparison = Nothing
                        , selected = Scenario.minHorizon
                        , version = Nothing
                        }
        , test "percent-encoded separators are decoded" <|
            \_ ->
                (Link.fromQuery "c=10%3A25%3A20%3A3%2C30%3A10%3A20%3A1").scenario.changes
                    |> Expect.equal
                        [ { period = 10, policy = { spending = 25, taxRatePct = 20, interestRatePct = 3 } }
                        , { period = 30, policy = { spending = 10, taxRatePct = 20, interestRatePct = 1 } }
                        ]
        , test "the version in the link selects the model" <|
            \_ ->
                (Link.fromQuery "v=pc-1").model
                    |> Expect.equal PcModel
        , test "an old version of a model still selects that model and is reported" <|
            \_ ->
                let
                    link =
                        Link.fromQuery "v=pc-0"
                in
                ( link.model, link.version )
                    |> Expect.equal ( PcModel, Just "pc-0" )
        , test "a link from before the interest rate existed still opens" <|
            \_ ->
                let
                    link =
                        Link.fromQuery "v=sim-1&g=20&t=20&n=80&p=16&c=15:30:20"
                in
                ( link.model, link.scenario.changes, link.selected )
                    |> Expect.equal
                        ( SimModel
                        , [ { period = 15
                            , policy = { spending = 30, taxRatePct = 20, interestRatePct = Policy.default.interestRatePct }
                            }
                          ]
                        , 16
                        )
        , test "a comparison scenario takes the horizon of the main one" <|
            \_ ->
                (Link.fromQuery "n=30&bg=10").comparison
                    |> Expect.equal
                        (Just
                            { initial = { spending = 10, taxRatePct = 20, interestRatePct = 2.5 }
                            , changes = []
                            , horizon = 30
                            }
                        )
        ]
