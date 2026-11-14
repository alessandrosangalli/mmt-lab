module Link exposing (Link, fromQuery, modelVersion, toQuery)

{-| A scenario written into, and read back from, a URL query string, so that
a link reproduces an experiment exactly.

    v=sim-1&g=20&t=20&n=40&p=40&c=10:25:20,20:25:30

`g` and `t` are the initial spending and tax rate, `n` the horizon, `p` the
period in focus, and `c` the changes as `period:spending:taxRate`.

-}

import Dict exposing (Dict)
import Scenario exposing (Change, Scenario)
import Url


type alias Link =
    { scenario : Scenario
    , selected : Int
    , version : Maybe String
    }


{-| Identifies the model and its equations. It changes whenever the same
scenario would produce different numbers.
-}
modelVersion : String
modelVersion =
    "sim-1"


toQuery : Scenario -> Int -> String
toQuery scenario selected =
    String.join "&"
        ([ "v=" ++ modelVersion
         , "g=" ++ String.fromFloat scenario.initial.spending
         , "t=" ++ String.fromFloat scenario.initial.taxRatePct
         , "n=" ++ String.fromInt scenario.horizon
         , "p=" ++ String.fromInt selected
         ]
            ++ changesField scenario.changes
        )


changesField : List Change -> List String
changesField changes =
    if List.isEmpty changes then
        []

    else
        [ "c=" ++ String.join "," (List.map encodeChange changes) ]


encodeChange : Change -> String
encodeChange change =
    String.join ":"
        [ String.fromInt change.period
        , String.fromFloat change.policy.spending
        , String.fromFloat change.policy.taxRatePct
        ]


{-| Never fails: anything missing or malformed falls back to the default
scenario, and every value is brought into range.
-}
fromQuery : String -> Link
fromQuery query =
    let
        fields =
            parseFields query

        base =
            Scenario.default

        floatField key fallback =
            Dict.get key fields
                |> Maybe.andThen String.toFloat
                |> Maybe.withDefault fallback

        intField key fallback =
            Dict.get key fields
                |> Maybe.andThen String.toInt
                |> Maybe.withDefault fallback

        scenario =
            Scenario.sanitize
                { initial =
                    { spending = floatField "g" base.initial.spending
                    , taxRatePct = floatField "t" base.initial.taxRatePct
                    }
                , changes =
                    Dict.get "c" fields
                        |> Maybe.map decodeChanges
                        |> Maybe.withDefault []
                , horizon = intField "n" base.horizon
                }
    in
    { scenario = scenario
    , selected = clamp 1 scenario.horizon (intField "p" scenario.horizon)
    , version = Dict.get "v" fields
    }


parseFields : String -> Dict String String
parseFields query =
    let
        body =
            if String.startsWith "?" query then
                String.dropLeft 1 query

            else
                query
    in
    body
        |> String.split "&"
        |> List.filterMap toPair
        |> Dict.fromList


toPair : String -> Maybe ( String, String )
toPair part =
    case String.split "=" part of
        [ key, value ] ->
            Just ( key, Url.percentDecode value |> Maybe.withDefault value )

        _ ->
            Nothing


decodeChanges : String -> List Change
decodeChanges raw =
    raw
        |> String.split ","
        |> List.filterMap decodeChange


decodeChange : String -> Maybe Change
decodeChange raw =
    case String.split ":" raw of
        [ period, spending, taxRatePct ] ->
            Maybe.map3
                (\p g t -> { period = p, policy = { spending = g, taxRatePct = t } })
                (String.toInt period)
                (String.toFloat spending)
                (String.toFloat taxRatePct)

        _ ->
            Nothing
