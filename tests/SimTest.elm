module SimTest exposing (suite)

import Expect exposing (FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer)
import Model.Sim as Sim exposing (Policy)
import Sfc.Matrix as Matrix exposing (Sector(..))
import Test exposing (Test, describe, fuzz, fuzz2, test)


{-| Any policy the sliders can produce.
-}
policyFuzzer : Fuzzer Policy
policyFuzzer =
    Fuzz.map2 Policy
        (Fuzz.floatRange 0 50)
        (Fuzz.floatRange 5 50)


suite : Test
suite =
    describe "Model SIM"
        [ test "first period matches the hand-checked numbers" <|
            \_ ->
                let
                    outcome =
                        Sim.step { spending = 20, taxRatePct = 20 } 0
                in
                Expect.all
                    [ \o -> Expect.within (Absolute 0.001) 38.4615 o.income
                    , \o -> Expect.within (Absolute 0.001) 12.3077 o.moneyChange
                    ]
                    outcome
        , fuzz2 policyFuzzer (Fuzz.intRange 1 60) "every sector's column sums to zero in any period" <|
            \policy count ->
                case Sim.advanceBy count policy [] of
                    latest :: _ ->
                        Matrix.isBalanced Sim.sectors (Sim.flows latest.outcome)
                            |> Expect.equal True

                    [] ->
                        Expect.fail "advanceBy returned an empty history"
        , fuzz policyFuzzer "income converges to spending divided by the tax rate" <|
            \policy ->
                case Sim.advanceBy 500 policy [] of
                    latest :: _ ->
                        Expect.within (Absolute 0.001) (Sim.steadyStateIncome policy) latest.outcome.income

                    [] ->
                        Expect.fail "advanceBy returned an empty history"
        , fuzz policyFuzzer "household money equals the sum of all past deficits" <|
            \policy ->
                let
                    history =
                        Sim.advanceBy 40 policy []

                    deficits =
                        List.sum (List.map (\period -> period.outcome.spending - period.outcome.taxes) history)
                in
                case history of
                    latest :: _ ->
                        Expect.within (AbsoluteOrRelative 1.0e-6 1.0e-9) deficits latest.money

                    [] ->
                        Expect.fail "advanceBy returned an empty history"
        , describe "Sfc.Matrix"
            [ test "a payment with no counterpart does not balance" <|
                \_ ->
                    Matrix.isBalanced [ Households, Firms ]
                        [ { label = "one-way", from = Households, to = Firms, amount = 10 } ]
                        |> Expect.equal False
            , test "a flow to a sector outside the model does not balance" <|
                \_ ->
                    Matrix.isBalanced [ Households, Firms ]
                        [ { label = "leak", from = Households, to = RestOfWorld, amount = 0 } ]
                        |> Expect.equal False
            , test "a payment and its return balance" <|
                \_ ->
                    Matrix.isBalanced [ Households, Firms ]
                        [ { label = "out", from = Households, to = Firms, amount = 10 }
                        , { label = "back", from = Firms, to = Households, amount = 10 }
                        ]
                        |> Expect.equal True
            ]
        ]
