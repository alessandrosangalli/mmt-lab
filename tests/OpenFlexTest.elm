module OpenFlexTest exposing (suite)

import Expect exposing (FloatingPointTolerance(..))
import Model.OpenFlex as OpenFlex exposing (Params, Vars)
import Sfc.Matrix as Matrix
import Test exposing (Test, describe, test)


book : Params
book =
    OpenFlex.bookParams


{-| The parameters in force when one of them changes for good in period 5.
-}
from5 : (Params -> Params) -> Int -> Params
from5 change period =
    if period >= 5 then
        change book

    else
        book


at : Int -> List Vars -> Maybe Vars
at period solved =
    List.head (List.drop (period - 1) solved)


{-| Check a few variables of one period against numbers from the prototype
the model was generated with.
-}
expectPeriod : Int -> List ( Vars -> Float, Float ) -> Result OpenFlex.Failure (List Vars) -> Expect.Expectation
expectPeriod period expected result =
    case Result.toMaybe result |> Maybe.andThen (at period) of
        Just vars ->
            Expect.all
                (List.map
                    (\( pick, value ) solved -> Expect.within (AbsoluteOrRelative 1.0e-7 1.0e-7) value (pick solved))
                    expected
                )
                vars

        Nothing ->
            Expect.fail "the simulation did not reach that period"


{-| Every period's payments balance in every sector.
-}
expectBalanced : (Int -> Params) -> Expect.Expectation
expectBalanced paramsAt =
    case OpenFlex.simulate paramsAt 120 of
        Ok solved ->
            let
                lagged =
                    OpenFlex.steadyState :: solved

                balanced period previous current =
                    Matrix.isBalanced OpenFlex.sectors
                        (OpenFlex.flows (paramsAt (period - 1)) previous (paramsAt period) current)
            in
            List.map3 balanced (List.range 1 120) lagged solved
                |> List.all identity
                |> Expect.equal True

        Err failure ->
            Expect.fail ("failed in period " ++ String.fromInt failure.period)


suite : Test
suite =
    describe "Model OPENFLEX"
        [ test "the steady state reproduces the values published in the book" <|
            \_ ->
                Expect.all
                    (List.map
                        (\( pick, published ) vars -> Expect.within (Relative 1.0e-4) published (pick vars))
                        [ ( .y_k_uk, 97.392 )
                        , ( .y_k_us, 97.403 )
                        , ( .xr_uk, 1.0003 )
                        , ( .pds_uk, 0.95648 )
                        , ( .v_uk, 145.97 )
                        , ( .cons_uk, 77.851 )
                        , ( .x_k_uk, 11.926 )
                        , ( .im_k_uk, 11.928 )
                        , ( .t_uk, 19.463 )
                        , ( .b_ukus_d, 36.493 )
                        , ( .h_uk_d, 7.2987 )
                        ]
                    )
                    OpenFlex.steadyState
        , test "stepping from the steady state changes nothing" <|
            \_ ->
                case OpenFlex.step book OpenFlex.steadyState book of
                    Ok vars ->
                        Expect.all
                            [ \v -> Expect.within (Absolute 1.0e-9) OpenFlex.steadyState.y_k_uk v.y_k_uk
                            , \v -> Expect.within (Absolute 1.0e-9) OpenFlex.steadyState.xr_uk v.xr_uk
                            , \v -> Expect.within (Absolute 1.0e-9) OpenFlex.steadyState.b_uk_s v.b_uk_s
                            , \v -> Expect.within (Absolute 1.0e-9) 0 v.cab_uk
                            ]
                            vars

                    Err _ ->
                        Expect.fail "the steady state did not solve"
        , test "a fall in home exports: period 20 matches the prototype" <|
            \_ ->
                OpenFlex.simulate (from5 (\p -> { p | eps0 = -2.2 })) 120
                    |> expectPeriod 20
                        [ ( .xr_uk, 0.890803893 )
                        , ( .y_k_uk, 96.93942825 )
                        , ( .cab_uk, -0.3837172473 )
                        , ( .pds_uk, 0.959900147 )
                        ]
        , test "a fall in home exports: the currency depreciates and the current account closes" <|
            \_ ->
                OpenFlex.simulate (from5 (\p -> { p | eps0 = -2.2 })) 120
                    |> expectPeriod 120
                        [ ( .xr_uk, 0.7731560792 )
                        , ( .y_k_uk, 99.52054512 )
                        , ( .cab_uk, -0.009238522738 )
                        ]
        , test "a rise in foreign government spending: period 20 matches the prototype" <|
            \_ ->
                OpenFlex.simulate (from5 (\p -> { p | g_k_us = 18 })) 120
                    |> expectPeriod 20
                        [ ( .xr_uk, 1.116126406 )
                        , ( .y_k_uk, 97.50628691 )
                        , ( .cab_uk, 0.2551211555 )
                        ]
        , test "a rise in home government spending: period 120 matches the prototype" <|
            \_ ->
                OpenFlex.simulate (from5 (\p -> { p | g_k_uk = 20 })) 120
                    |> expectPeriod 120
                        [ ( .xr_uk, 0.6393424294 )
                        , ( .y_k_uk, 124.388799 )
                        , ( .cab_uk, -0.01715312801 )
                        ]
        , test "a rise in the home interest rate to 4%: period 20 matches the prototype" <|
            \_ ->
                OpenFlex.simulate (from5 (\p -> { p | r_uk = 0.04 })) 120
                    |> expectPeriod 20
                        [ ( .xr_uk, 0.9438775609 )
                        , ( .y_k_uk, 101.6753084 )
                        , ( .cab_uk, -1.05097248 )
                        ]
        , test "the baseline's payments balance in every period" <|
            \_ ->
                expectBalanced (\_ -> book)
        , test "payments balance through a fall in home exports" <|
            \_ ->
                expectBalanced (from5 (\p -> { p | eps0 = -2.2 }))
        , test "payments balance through a rise in home spending and in the home interest rate" <|
            \_ ->
                expectBalanced (from5 (\p -> { p | g_k_uk = 20, r_uk = 0.04 }))
        , test "a home interest rate of 6% has no solution after a while, and says so" <|
            \_ ->
                case OpenFlex.simulate (from5 (\p -> { p | r_uk = 0.06 })) 120 of
                    Err failure ->
                        Expect.all
                            [ \f -> Expect.atLeast 6 f.period
                            , \f -> Expect.atMost 40 f.period
                            ]
                            failure

                    Ok _ ->
                        Expect.fail "expected the simulation to fail"
        ]
