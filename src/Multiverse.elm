module Multiverse exposing (Cell, Outcome(..), Span(..), axisRange, axisValues, classify, halfStep, row, steps)

{-| The same scenario run under many combinations of premises, to show which
conclusions survive when the premises change.

A result that holds for one hand-picked set of parameters says little. This
module runs a grid of values for two premises and reports, for each
combination, how the economy ends up.

-}

import Dict
import Engine exposing (Run)
import Premise exposing (Premise)
import Scenario exposing (Scenario)


{-| How a run ends: with the external accounts back in balance, still moving
when the periods run out, or with no solution from some period on.
-}
type Outcome
    = Settles
    | StillAdjusting
    | NoSolution Int


type alias Cell =
    { x : Float
    , y : Float
    , outcome : Outcome
    }


{-| Points along each axis.
-}
steps : Int
steps =
    11


{-| What an axis of the map covers: the whole range of the premise's control,
or only the range the Brazilian estimates read so far span. A premise with no
published range is always shown whole.
-}
type Span
    = Whole
    | Published


axisRange : Span -> Premise -> ( Float, Float )
axisRange span premise =
    case ( span, premise.published ) of
        ( Published, Just range ) ->
            range

        _ ->
            ( premise.lowest, premise.highest )


{-| The values of a premise along an axis, in even steps.
-}
axisValues : Span -> Premise -> List Float
axisValues span premise =
    let
        ( low, high ) =
            axisRange span premise

        at index =
            low + (high - low) * toFloat index / toFloat (steps - 1)

        tidy number =
            toFloat (round (number * 1000000)) / 1000000
    in
    List.map (\index -> tidy (at index)) (List.range 0 (steps - 1))


{-| Half the distance between two neighbouring values of an axis: how far a
square of the map reaches on each side of its value.
-}
halfStep : Span -> Premise -> Float
halfStep span premise =
    let
        ( low, high ) =
            axisRange span premise
    in
    (high - low) / toFloat (steps - 1) / 2


{-| A run has settled when, in its last period, the balance with the rest of
the world is within a thousandth of income, or when its first extra series
(the exchange rate, in the open models) has moved less than 1% over the last
ten periods.

The second test is for economies on a growth path, where the balance with the
rest of the world does not rest at zero.

-}
classify : Run -> Outcome
classify run =
    case run.failedAt of
        Just period ->
            NoSolution period

        Nothing ->
            let
                recent =
                    List.reverse run.snapshots

                firstSeries snapshot =
                    Maybe.map .value (List.head snapshot.charts)

                steady latest =
                    case ( firstSeries latest, Maybe.andThen firstSeries (List.head (List.drop 10 recent)) ) of
                        ( Just now, Just before ) ->
                            abs (now - before) <= 0.01 * abs before

                        _ ->
                            False
            in
            case List.head recent of
                Just latest ->
                    if abs latest.foreignBalance <= 0.001 * abs latest.income || steady latest then
                        Settles

                    else
                        StillAdjusting

                Nothing ->
                    StillAdjusting


{-| One line of the grid: every value of the horizontal premise, at one value
of the vertical one. Everything else in the scenario stays as it is.
-}
row : (Scenario -> Run) -> Scenario -> Span -> Premise -> Premise -> Float -> List Cell
row run scenario span horizontal vertical y =
    let
        cell x =
            { x = x
            , y = y
            , outcome =
                classify
                    (run
                        { scenario
                            | premises =
                                scenario.premises
                                    |> Dict.insert horizontal.key x
                                    |> Dict.insert vertical.key y
                        }
                    )
            }
    in
    List.map cell (axisValues span horizontal)
