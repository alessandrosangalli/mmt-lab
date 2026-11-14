module Format exposing (decimal, fixed, indicator, signed, signedIndicator)

{-| Number formatting in the Brazilian convention (decimal comma).
-}


{-| One decimal place: `decimal 38.46 == "38,5"`.
-}
decimal : Float -> String
decimal x =
    let
        tenths =
            round (abs x * 10)

        sign =
            if x < 0 && tenths /= 0 then
                "−"

            else
                ""
    in
    sign ++ String.fromInt (tenths // 10) ++ "," ++ String.fromInt (modBy 10 tenths)


{-| Like `decimal`, with an explicit plus sign on positive values.
-}
signed : Float -> String
signed x =
    if x > 0 && round (x * 10) /= 0 then
        "+" ++ decimal x

    else
        decimal x


{-| Like `decimal`, but small values such as an exchange rate or a price
level keep three decimal places, where one would hide every movement.
-}
indicator : Float -> String
indicator x =
    if abs x < 10 then
        fixed 3 x

    else
        decimal x


signedIndicator : Float -> String
signedIndicator x =
    if abs x < 10 then
        if x > 0 && round (x * 1000) /= 0 then
            "+" ++ fixed 3 x

        else
            fixed 3 x

    else
        signed x


{-| A given number of decimal places: `fixed 2 0.7 == "0,70"`.
-}
fixed : Int -> Float -> String
fixed places x =
    let
        scale =
            10 ^ places

        scaled =
            round (abs x * toFloat scale)

        sign =
            if x < 0 && scaled /= 0 then
                "−"

            else
                ""

        fraction =
            String.padLeft places '0' (String.fromInt (modBy scale scaled))
    in
    sign ++ String.fromInt (scaled // scale) ++ "," ++ fraction
