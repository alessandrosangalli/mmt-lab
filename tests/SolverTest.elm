module SolverTest exposing (suite)

import Expect exposing (FloatingPointTolerance(..))
import Sfc.Solver as Solver exposing (Error(..))
import Test exposing (Test, describe, test)


settings : (Float -> Float) -> Solver.Settings Float
settings sweep =
    { sweep = sweep
    , distance = \before after -> abs (after - before)
    , tolerance = 1.0e-12
    , maxSweeps = 200
    }


suite : Test
suite =
    describe "Sfc.Solver"
        [ test "finds the fixed point of a contraction" <|
            \_ ->
                case Solver.fixedPoint (settings cos) 1 of
                    Ok value ->
                        Expect.within (Absolute 1.0e-9) 0.7390851332 value

                    Err _ ->
                        Expect.fail "did not converge"
        , test "returns the start when it already is the solution" <|
            \_ ->
                Solver.fixedPoint (settings identity) 42
                    |> Expect.equal (Ok 42)
        , test "reports a guess that never settles" <|
            \_ ->
                Solver.fixedPoint (settings (\x -> 1 - x)) 3
                    |> Expect.equal (Err (DidNotConverge 200))
        , test "reports a guess that stops being a number" <|
            \_ ->
                Solver.fixedPoint (settings (\x -> sqrt (x - 10))) 1
                    |> Expect.equal (Err (NotFinite 1))
        , test "reports a guess that runs off to infinity" <|
            \_ ->
                case Solver.fixedPoint (settings (\x -> x * x)) 10 of
                    Err (NotFinite _) ->
                        Expect.pass

                    other ->
                        Expect.fail ("expected NotFinite, got " ++ Debug.toString other)
        ]
