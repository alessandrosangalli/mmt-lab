module Sfc.Solver exposing (Error(..), Settings, fixedPoint)

{-| Solving a period whose equations depend on one another.

When income depends on consumption and consumption on income, there is no
order in which the equations can simply be computed. The Gauss-Seidel method
makes a guess, passes over every equation once to improve it, and repeats
until a pass changes nothing.

A model that has no solution does not settle. This module reports that as an
error instead of returning the last guess.

-}


type Error
    = DidNotConverge Int
    | NotFinite Int


{-| `sweep` is one pass over the equations. `distance` measures how much a
pass changed the guess; solving stops when it falls below `tolerance`, or
fails after `maxSweeps` passes.
-}
type alias Settings a =
    { sweep : a -> a
    , distance : a -> a -> Float
    , tolerance : Float
    , maxSweeps : Int
    }


fixedPoint : Settings a -> a -> Result Error a
fixedPoint settings start =
    iterate settings 1 start


iterate : Settings a -> Int -> a -> Result Error a
iterate settings count current =
    if count > settings.maxSweeps then
        Err (DidNotConverge settings.maxSweeps)

    else
        let
            next =
                settings.sweep current

            change =
                settings.distance current next
        in
        if isNaN change || isInfinite change then
            Err (NotFinite count)

        else if change < settings.tolerance then
            Ok next

        else
            iterate settings (count + 1) next
