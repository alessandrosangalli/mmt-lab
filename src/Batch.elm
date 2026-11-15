port module Batch exposing (main)

{-| The multiverse run: the Brazilian model under every combination of its
premises inside the ranges the estimates read so far span, for a handful of
policy changes. It has no screen. `tools/multiverse/run.js` runs it in the
build and writes what comes out.
-}

import Dict
import Json.Encode as Encode
import Models exposing (ModelId(..))
import Multiverse exposing (Outcome(..), Pace(..))
import Platform
import Policy exposing (Policy)
import Premise exposing (Premise, Premises)


port report : Encode.Value -> Cmd msg


main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), report results )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


horizon : Int
horizon =
    120


{-| How many values each premise takes inside its published range. The
premise the result hangs on most gets the finest grid.
-}
valuesFor : Premise -> Int
valuesFor premise =
    if premise.key == "mu1" then
        9

    else
        3


ranged : List Premise
ranged =
    List.filter (\premise -> premise.published /= Nothing) (Models.info BrazilModel).premises


choices : List ( String, List Float )
choices =
    List.filterMap
        (\premise -> Maybe.map (\range -> ( premise.key, Multiverse.spread (valuesFor premise) range )) premise.published)
        ranged


type alias Change =
    { key : String
    , name : String
    , apply : Policy -> Policy
    }


changes : List Change
changes =
    [ Change "spending-up" "Gasto público de 18 para 19" (\policy -> { policy | spending = policy.spending + 1 })
    , Change "spending-down" "Gasto público de 18 para 17" (\policy -> { policy | spending = policy.spending - 1 })
    , Change "rate-up" "Juro meio ponto maior por trimestre" (\policy -> { policy | interestRatePct = policy.interestRatePct + 0.5 })
    , Change "rate-down" "Juro meio ponto menor por trimestre" (\policy -> { policy | interestRatePct = policy.interestRatePct - 0.5 })
    , Change "tax-up" "Alíquota um ponto maior" (\policy -> { policy | taxRatePct = policy.taxRatePct + 1 })
    ]


results : Encode.Value
results =
    Encode.object
        [ ( "model", Encode.string (Models.info BrazilModel).version )
        , ( "horizon", Encode.int horizon )
        , ( "premises"
          , Encode.list
                (\premise ->
                    Encode.object
                        [ ( "key", Encode.string premise.key )
                        , ( "name", Encode.string premise.name )
                        , ( "values", Encode.list Encode.float (Maybe.withDefault [] (Dict.get premise.key (Dict.fromList choices))) )
                        ]
                )
                ranged
          )
        , ( "changes"
          , Encode.list
                (\change ->
                    Encode.object
                        [ ( "key", Encode.string change.key )
                        , ( "name", Encode.string change.name )
                        , ( "runs", Encode.list (encodeRun change) (Multiverse.combinations choices) )
                        ]
                )
                changes
          )
        ]


encodeRun : Change -> Premises -> Encode.Value
encodeRun change premises =
    let
        base =
            Models.defaultScenario BrazilModel

        run =
            Models.run BrazilModel
                { base | initial = change.apply base.initial, horizon = horizon, premises = premises }

        latest =
            List.head (List.reverse run.snapshots)

        firstSeries =
            latest
                |> Maybe.andThen (\snapshot -> List.head snapshot.charts)
                |> Maybe.map .value

        debtRatio =
            latest
                |> Maybe.andThen (\snapshot -> List.head (List.filter (\indicator -> indicator.name == "Dívida pública ÷ PIB") snapshot.indicators))
                |> Maybe.map .value

        optional =
            Maybe.map Encode.float >> Maybe.withDefault Encode.null
    in
    Encode.object
        [ ( "premises", Encode.dict identity Encode.float premises )
        , ( "outcome"
          , Encode.string
                (case Multiverse.classify run of
                    Settles ->
                        "settles"

                    StillAdjusting ->
                        case Multiverse.pace (List.filterMap (\snapshot -> Maybe.map .value (List.head snapshot.charts)) run.snapshots) of
                            Just Speeding ->
                                "speeding"

                            _ ->
                                "slowing"

                    NoSolution _ ->
                        "failed"
                )
          )
        , ( "failedAt", Maybe.withDefault Encode.null (Maybe.map Encode.int run.failedAt) )
        , ( "rate", optional firstSeries )
        , ( "debt", optional debtRatio )
        ]
