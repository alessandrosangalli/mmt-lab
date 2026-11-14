module Premise exposing (Premise, Premises, sanitize, value)

{-| A premise is an assumption of a model that economists disagree about and
that changes the result. The laboratory puts each one on screen as a
control, instead of leaving it buried in the code.
-}

import Dict exposing (Dict)


{-| `key` names the premise in a link. `note` says what it means, what the
book assumes and what has been estimated for Brazil.
-}
type alias Premise =
    { key : String
    , name : String
    , note : String
    , lowest : Float
    , highest : Float
    , step : Float
    , default : Float
    }


{-| The premises a scenario departs from. A premise left out keeps the
model's default.
-}
type alias Premises =
    Dict String Float


{-| The value in force, kept inside the premise's range.
-}
value : Premise -> Premises -> Float
value premise premises =
    Dict.get premise.key premises
        |> Maybe.withDefault premise.default
        |> clamp premise.lowest premise.highest


{-| Keep only premises the model knows, inside their ranges, and only where
they differ from the default.
-}
sanitize : List Premise -> Premises -> Premises
sanitize known premises =
    let
        entry premise =
            let
                current =
                    value premise premises
            in
            if current == premise.default then
                Nothing

            else
                Just ( premise.key, current )
    in
    Dict.fromList (List.filterMap entry known)
