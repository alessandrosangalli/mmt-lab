module PcTest exposing (suite)

import Expect exposing (FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer)
import Model.Pc as Pc exposing (Policy)
import Sfc.Matrix as Matrix
import Test exposing (Test, describe, fuzz, fuzz2, test)


baseline : Policy
baseline =
    { spending = 20, taxRatePct = 20, interestRatePct = 2.5 }


{-| Policies for which the book's portfolio parameters stay meaningful.
-}
policyFuzzer : Fuzzer Policy
policyFuzzer =
    Fuzz.map3 Policy
        (Fuzz.floatRange 1 50)
        (Fuzz.floatRange 10 40)
        (Fuzz.floatRange 0 5)


run : Int -> Policy -> List Pc.Period
run count policy =
    Pc.advanceBy count Pc.bookBehaviour policy []


latestOf : List Pc.Period -> Maybe Pc.Period
latestOf history =
    List.head history


suite : Test
suite =
    describe "Model PC"
        [ test "first period matches the hand-checked numbers" <|
            \_ ->
                case latestOf (run 1 baseline) of
                    Just period ->
                        Expect.all
                            [ \p -> Expect.within (Absolute 0.001) 38.4615 p.outcome.income
                            , \p -> Expect.within (Absolute 0.001) 12.3077 p.state.wealth
                            , \p -> Expect.within (Absolute 0.001) 9.0462 p.state.householdBills
                            , \p -> Expect.within (Absolute 0.001) 3.2615 p.state.householdMoney
                            , \p -> Expect.within (Absolute 0.001) 12.3077 p.state.billsIssued
                            ]
                            period

                    Nothing ->
                        Expect.fail "no period"
        , test "the closed form gives the book's steady-state income" <|
            \_ ->
                (Pc.steadyState Pc.bookBehaviour baseline).income
                    |> Expect.within (Absolute 0.001) 106.4865
        , test "the baseline simulation reaches that steady state" <|
            \_ ->
                case latestOf (run 600 baseline) of
                    Just period ->
                        Expect.within (Absolute 0.001) 106.4865 period.outcome.income

                    Nothing ->
                        Expect.fail "no period"
        , fuzz policyFuzzer "the simulation converges to the closed-form steady state" <|
            \policy ->
                let
                    expected =
                        Pc.steadyState Pc.bookBehaviour policy
                in
                case latestOf (run 2000 policy) of
                    Just period ->
                        Expect.all
                            [ \p -> Expect.within (AbsoluteOrRelative 1.0e-6 1.0e-6) expected.income p.outcome.income
                            , \p -> Expect.within (AbsoluteOrRelative 1.0e-6 1.0e-6) expected.wealth p.state.wealth
                            , \p -> Expect.within (AbsoluteOrRelative 1.0e-6 1.0e-6) expected.householdBills p.state.householdBills
                            ]
                            period

                    Nothing ->
                        Expect.fail "no period"
        , fuzz2 policyFuzzer (Fuzz.intRange 1 80) "every sector's column sums to zero in any period" <|
            \policy count ->
                run count policy
                    |> List.all (\period -> Matrix.isBalanced Pc.sectors (Pc.flows period.outcome))
                    |> Expect.equal True
        , fuzz2 policyFuzzer (Fuzz.intRange 1 80) "the money issued equals the money households hold" <|
            \policy count ->
                case latestOf (run count policy) of
                    Just period ->
                        Expect.within (AbsoluteOrRelative 1.0e-9 1.0e-9) period.state.householdMoney period.state.moneyIssued

                    Nothing ->
                        Expect.fail "no period"
        , fuzz2 policyFuzzer (Fuzz.intRange 1 80) "bills issued are held by households and the central bank" <|
            \policy count ->
                case latestOf (run count policy) of
                    Just period ->
                        Expect.within (AbsoluteOrRelative 1.0e-9 1.0e-9)
                            period.state.billsIssued
                            (period.state.householdBills + period.state.centralBankBills)

                    Nothing ->
                        Expect.fail "no period"
        , test "a higher interest rate raises steady-state income" <|
            \_ ->
                let
                    lower =
                        Pc.steadyState Pc.bookBehaviour baseline

                    higher =
                        Pc.steadyState Pc.bookBehaviour { baseline | interestRatePct = 3.5 }
                in
                Expect.all
                    [ \_ -> Expect.greaterThan lower.income higher.income
                    , \_ -> Expect.within (Absolute 0.001) 110.0901 higher.income
                    ]
                    ()
        , test "a rate change moves the simulation to the new steady state" <|
            \_ ->
                let
                    raised =
                        { baseline | interestRatePct = 3.5 }

                    history =
                        Pc.advanceBy 600 Pc.bookBehaviour raised (run 200 baseline)
                in
                case latestOf history of
                    Just period ->
                        Expect.within (Absolute 0.001) 110.0901 period.outcome.income

                    Nothing ->
                        Expect.fail "no period"
        ]
