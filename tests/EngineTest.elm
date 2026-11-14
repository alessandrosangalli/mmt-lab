module EngineTest exposing (suite)

import Dict
import Engine exposing (Snapshot)
import Expect exposing (FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer)
import Model.Pc as Pc
import Models exposing (ModelId(..))
import Policy exposing (Policy)
import Scenario exposing (Scenario)
import Sfc.Matrix as Matrix
import Test exposing (Test, describe, fuzz2, test)


{-| Policies inside the range where the closed models stay well behaved.
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
            , premises = Dict.empty
            }
        )
        policyFuzzer
        policyFuzzer
        (Fuzz.intRange 2 40)


{-| Every model. The open economy stops having a solution under some of
these policies; the properties must hold for every period it does solve.
-}
modelFuzzer : Fuzzer ModelId
modelFuzzer =
    Fuzz.oneOfValues Models.all


closedModelFuzzer : Fuzzer ModelId
closedModelFuzzer =
    Fuzz.oneOfValues [ SimModel, PcModel ]


everySnapshot : (Snapshot -> Bool) -> ModelId -> Scenario -> Expect.Expectation
everySnapshot holds model scenario =
    (Models.run model scenario).snapshots
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
        , fuzz2 modelFuzzer scenarioFuzzer "the three sectoral balances add up to zero, in every model" <|
            \model scenario ->
                everySnapshot
                    (\snapshot ->
                        closeToZero snapshot.income
                            (snapshot.privateSurplus + snapshot.governmentBalance + snapshot.foreignBalance)
                    )
                    model
                    scenario
        , fuzz2 closedModelFuzzer scenarioFuzzer "a closed model has no foreign balance and always has a solution" <|
            \model scenario ->
                let
                    result =
                        Models.run model scenario
                in
                ( List.all (\snapshot -> snapshot.foreignBalance == 0) result.snapshots
                , List.length result.snapshots
                , result.failedAt
                )
                    |> Expect.equal ( True, 40, Nothing )
        , fuzz2 closedModelFuzzer scenarioFuzzer "in a closed model, household wealth is the sum of the private surpluses so far" <|
            \model scenario ->
                let
                    snapshots =
                        (Models.run model scenario).snapshots

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
                (Models.run PcModel Scenario.default).snapshots
                    |> List.map .income
                    |> Expect.equal
                        (Pc.advanceBy Scenario.default.horizon Pc.bookBehaviour Scenario.default.initial []
                            |> List.reverse
                            |> List.map (\period -> period.outcome.income)
                        )
        , test "the open economy stays at rest under its default policy" <|
            \_ ->
                let
                    result =
                        Models.run OpenModel (Models.defaultScenario OpenModel)

                    incomes =
                        List.map .income result.snapshots
                in
                ( result.failedAt
                , List.length incomes
                , List.all (\income -> abs (income - 97.394) < 0.001) incomes
                )
                    |> Expect.equal ( Nothing, 40, True )
        , test "in the open economy, more government spending weakens the currency and raises prices" <|
            \_ ->
                let
                    base =
                        Models.defaultScenario OpenModel

                    expansion =
                        { base | initial = { spending = 20, taxRatePct = 20, interestRatePct = 3 } }

                    exchangeRateAndPrices snapshot =
                        List.map .value snapshot.charts
                in
                case List.head (List.reverse (Models.run OpenModel expansion).snapshots) of
                    Just latest ->
                        case exchangeRateAndPrices latest of
                            [ exchangeRate, prices ] ->
                                ( exchangeRate < 0.8, prices > 0.96, latest.income > 110 )
                                    |> Expect.equal ( True, True, True )

                            _ ->
                                Expect.fail "expected two extra series"

                    Nothing ->
                        Expect.fail "no periods"
        , test "the open economy reports the period where it stops having a solution" <|
            \_ ->
                let
                    base =
                        Models.defaultScenario OpenModel

                    result =
                        Models.run OpenModel { base | initial = { spending = 16, taxRatePct = 20, interestRatePct = 6 } }
                in
                ( result.failedAt /= Nothing
                , Maybe.map (\period -> List.length result.snapshots == period - 1) result.failedAt
                )
                    |> Expect.equal ( True, Just True )
        , test "with the Brazilian estimate of how exports respond to the currency, a spending rise has no solution in period 108, as in the prototype" <|
            \_ ->
                let
                    base =
                        Models.defaultScenario OpenModel

                    result =
                        Models.run OpenModel
                            { base
                                | initial = { spending = 20, taxRatePct = 20, interestRatePct = 3 }
                                , horizon = 120
                                , premises = Dict.fromList [ ( "eps1", 0.01 ) ]
                            }
                in
                result.failedAt
                    |> Expect.equal (Just 108)
        , test "full pass-through to import prices raises the price level more, matching the prototype" <|
            \_ ->
                let
                    base =
                        Models.defaultScenario OpenModel

                    run premises =
                        (Models.run OpenModel
                            { base
                                | initial = { spending = 20, taxRatePct = 20, interestRatePct = 3 }
                                , premises = premises
                            }
                        ).snapshots
                            |> List.reverse
                            |> List.head
                            |> Maybe.map (\snapshot -> List.map .value snapshot.charts)
                            |> Maybe.withDefault []
                in
                case ( run Dict.empty, run (Dict.fromList [ ( "nu1m", 1 ) ]) ) of
                    ( [ bookRate, bookPrices ], [ fullRate, fullPrices ] ) ->
                        Expect.all
                            [ \_ -> Expect.within (Absolute 1.0e-7) 0.700809203 bookRate
                            , \_ -> Expect.within (Absolute 1.0e-7) 0.9661389335 bookPrices
                            , \_ -> Expect.within (Absolute 1.0e-7) 0.6350964822 fullRate
                            , \_ -> Expect.within (Absolute 1.0e-7) 0.9833039919 fullPrices
                            ]
                            ()

                    _ ->
                        Expect.fail "expected two extra series in each run"
        , test "weaker portfolio reaction to interest softens the effect of a rate rise, matching the prototype" <|
            \_ ->
                let
                    base =
                        Models.defaultScenario OpenModel

                    exchangeRate premises =
                        (Models.run OpenModel
                            { base
                                | initial = { spending = 16, taxRatePct = 20, interestRatePct = 4 }
                                , premises = premises
                            }
                        ).snapshots
                            |> List.reverse
                            |> List.head
                            |> Maybe.andThen (\snapshot -> List.head snapshot.charts)
                            |> Maybe.map .value
                            |> Maybe.withDefault 0
                in
                Expect.all
                    [ \_ -> Expect.within (Absolute 1.0e-7) 0.7227069524 (exchangeRate Dict.empty)
                    , \_ -> Expect.within (Absolute 1.0e-7) 0.7999057983 (exchangeRate (Dict.fromList [ ( "port", 1 ) ]))
                    ]
                    ()
        , test "premises do not move the starting point of the open economy" <|
            \_ ->
                let
                    base =
                        Models.defaultScenario OpenModel

                    result =
                        Models.run OpenModel
                            { base | premises = Dict.fromList [ ( "eps1", 0.01 ), ( "nu1m", 1 ), ( "port", 1 ) ] }
                in
                ( result.failedAt
                , List.all (\snapshot -> abs (snapshot.income - 97.394) < 0.01) result.snapshots
                )
                    |> Expect.equal ( Nothing, True )
        , test "a version string names its model" <|
            \_ ->
                List.map Models.fromVersion [ "sim-1", "pc-1", "pc-7", "open-1", "other-1", "" ]
                    |> Expect.equal [ Just SimModel, Just PcModel, Just PcModel, Just OpenModel, Nothing, Nothing ]
        , test "every model's current version names itself" <|
            \_ ->
                List.map (\model -> Models.fromVersion (Models.info model).version) Models.all
                    |> Expect.equal (List.map Just Models.all)
        ]
