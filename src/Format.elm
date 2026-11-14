module Format exposing (decimal, signed)

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
