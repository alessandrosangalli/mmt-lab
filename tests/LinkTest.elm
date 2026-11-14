module LinkTest exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Link
import Model.Sim exposing (Policy)
import Scenario exposing (Change, Scenario)
import Test exposing (Test, describe, fuzz2, test)


policyFuzzer : Fuzzer Policy
policyFuzzer =
    Fuzz.map2 Policy
        (Fuzz.floatRange 0 50)
        (Fuzz.floatRange 5 50)


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


suite : Test
suite =
    describe "Link"
        [ fuzz2 scenarioFuzzer (Fuzz.intRange 1 Scenario.minHorizon) "a scenario survives the round trip through a link" <|
            \scenario selected ->
                Link.fromQuery (Link.toQuery scenario selected)
                    |> Expect.equal
                        { scenario = scenario
                        , selected = selected
                        , version = Just Link.modelVersion
                        }
        , test "an empty query gives the default scenario" <|
            \_ ->
                Link.fromQuery ""
                    |> Expect.equal
                        { scenario = Scenario.default
                        , selected = Scenario.default.horizon
                        , version = Nothing
                        }
        , test "a leading question mark is accepted" <|
            \_ ->
                (Link.fromQuery "?g=30").scenario.initial.spending
                    |> Expect.equal 30
        , test "garbage falls back to defaults and stays in range" <|
            \_ ->
                Link.fromQuery "?g=abc&t=&n=-3&c=1:2,xx,7:8:9:10&p=999&junk"
                    |> Expect.equal
                        { scenario =
                            { initial = Scenario.default.initial
                            , changes = []
                            , horizon = Scenario.minHorizon
                            }
                        , selected = Scenario.minHorizon
                        , version = Nothing
                        }
        , test "percent-encoded separators are decoded" <|
            \_ ->
                (Link.fromQuery "c=10%3A25%3A20%2C30%3A10%3A20").scenario.changes
                    |> Expect.equal
                        [ { period = 10, policy = { spending = 25, taxRatePct = 20 } }
                        , { period = 30, policy = { spending = 10, taxRatePct = 20 } }
                        ]
        , test "the version in the link is reported as written" <|
            \_ ->
                (Link.fromQuery "v=sim-0").version
                    |> Expect.equal (Just "sim-0")
        ]
