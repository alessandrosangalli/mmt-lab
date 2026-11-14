module Link exposing (Link, fromQuery, toQuery)

{-| A model and its scenarios written into, and read back from, a URL query
string, so that a link reproduces an experiment exactly.

    v=pc-1&g=20&t=20&i=2.5&n=40&p=40&c=10:25:20:3.5

`v` names the model and its version. `g`, `t` and `i` are the initial
spending, tax rate and interest rate, `n` the horizon, `p` the period in
focus, and `c` the changes as `period:spending:taxRate:interestRate`. A
second scenario to compare against uses `bg`, `bt`, `bi` and `bc`, and
shares the horizon.

Links written before the interest rate existed have no `i` and only three
parts per change. They still open, with the default interest rate.

-}

import Dict exposing (Dict)
import Models exposing (ModelId(..))
import Policy exposing (Policy)
import Scenario exposing (Change, Scenario)
import Url


type alias Link =
    { model : ModelId
    , scenario : Scenario
    , comparison : Maybe Scenario
    , selected : Int
    , version : Maybe String
    }


toQuery : ModelId -> Scenario -> Maybe Scenario -> Int -> String
toQuery model scenario comparison selected =
    String.join "&"
        ([ "v=" ++ (Models.info model).version ]
            ++ policyFields "" scenario.initial
            ++ [ "n=" ++ String.fromInt scenario.horizon
               , "p=" ++ String.fromInt selected
               ]
            ++ changesField "c" scenario.changes
            ++ comparisonFields comparison
        )


policyFields : String -> Policy -> List String
policyFields prefix policy =
    [ prefix ++ "g=" ++ String.fromFloat policy.spending
    , prefix ++ "t=" ++ String.fromFloat policy.taxRatePct
    , prefix ++ "i=" ++ String.fromFloat policy.interestRatePct
    ]


comparisonFields : Maybe Scenario -> List String
comparisonFields comparison =
    case comparison of
        Just other ->
            policyFields "b" other.initial ++ changesField "bc" other.changes

        Nothing ->
            []


changesField : String -> List Change -> List String
changesField key changes =
    if List.isEmpty changes then
        []

    else
        [ key ++ "=" ++ String.join "," (List.map encodeChange changes) ]


encodeChange : Change -> String
encodeChange change =
    String.join ":"
        [ String.fromInt change.period
        , String.fromFloat change.policy.spending
        , String.fromFloat change.policy.taxRatePct
        , String.fromFloat change.policy.interestRatePct
        ]


{-| Never fails: anything missing or malformed falls back to the default,
and every value is brought into range.
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

        policyOf prefix =
            { spending = floatField (prefix ++ "g") base.initial.spending
            , taxRatePct = floatField (prefix ++ "t") base.initial.taxRatePct
            , interestRatePct = floatField (prefix ++ "i") base.initial.interestRatePct
            }

        changesOf key =
            Dict.get key fields
                |> Maybe.map decodeChanges
                |> Maybe.withDefault []

        scenario =
            Scenario.sanitize
                { initial = policyOf ""
                , changes = changesOf "c"
                , horizon = intField "n" base.horizon
                }

        comparison =
            if List.any (\key -> Dict.member key fields) [ "bg", "bt", "bi", "bc" ] then
                Just
                    (Scenario.sanitize
                        { initial = policyOf "b"
                        , changes = changesOf "bc"
                        , horizon = scenario.horizon
                        }
                    )

            else
                Nothing

        version =
            Dict.get "v" fields
    in
    { model =
        version
            |> Maybe.andThen Models.fromVersion
            |> Maybe.withDefault SimModel
    , scenario = scenario
    , comparison = comparison
    , selected = clamp 1 scenario.horizon (intField "p" scenario.horizon)
    , version = version
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
    let
        build period spending taxRatePct interestRatePct =
            Maybe.map4
                (\p g t i ->
                    { period = p
                    , policy = { spending = g, taxRatePct = t, interestRatePct = i }
                    }
                )
                (String.toInt period)
                (String.toFloat spending)
                (String.toFloat taxRatePct)
                interestRatePct
    in
    case String.split ":" raw of
        [ period, spending, taxRatePct, interestRatePct ] ->
            build period spending taxRatePct (String.toFloat interestRatePct)

        [ period, spending, taxRatePct ] ->
            build period spending taxRatePct (Just Policy.default.interestRatePct)

        _ ->
            Nothing
