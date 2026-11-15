module PremiseTest exposing (suite)

import Dict
import Expect exposing (FloatingPointTolerance(..))
import Premise exposing (Premise)
import Test exposing (Test, describe, test)


share : Premise
share =
    { key = "share"
    , name = "A share"
    , note = ""
    , lowest = 0
    , highest = 1
    , step = 0.1
    , default = 0.7
    , brazil = Nothing
    , published = Nothing
    }


suite : Test
suite =
    describe "Premise"
        [ test "a premise left out keeps the default" <|
            \_ ->
                Premise.value share Dict.empty
                    |> Expect.within (Absolute 0) 0.7
        , test "a chosen value is used" <|
            \_ ->
                Premise.value share (Dict.fromList [ ( "share", 0.2 ) ])
                    |> Expect.within (Absolute 0) 0.2
        , test "a value outside the range is brought inside it" <|
            \_ ->
                List.map (\chosen -> Premise.value share (Dict.fromList [ ( "share", chosen ) ])) [ -3, 9 ]
                    |> Expect.equal [ 0, 1 ]
        , test "the Brazilian estimates replace only the premises that have one" <|
            \_ ->
                Premise.brazilian
                    [ { share | brazil = Just 0.1 }, { share | key = "other" } ]
                    (Dict.fromList [ ( "share", 0.9 ), ( "other", 0.4 ) ])
                    |> Dict.toList
                    |> Expect.equal [ ( "other", 0.4 ), ( "share", 0.1 ) ]
        , test "sanitize drops unknown premises, clamps the rest and leaves out defaults" <|
            \_ ->
                Premise.sanitize [ share, { share | key = "other" }, { share | key = "third" } ]
                    (Dict.fromList [ ( "share", 5 ), ( "other", 0.7 ), ( "unknown", 1 ) ])
                    |> Dict.toList
                    |> Expect.equal [ ( "share", 1 ) ]
        , test "a value is inside the published range when it is between its ends, give or take the margin" <|
            \_ ->
                let
                    ranged =
                        { share | published = Just ( 0.2, 0.4 ) }
                in
                [ Premise.isPublished 0 ranged 0.3
                , Premise.isPublished 0 ranged 0.45
                , Premise.isPublished 0.05 ranged 0.45
                , Premise.isPublished 0.05 ranged 0.1
                , Premise.isPublished 1 share 0.3
                ]
                    |> Expect.equal [ True, False, True, False, False ]
        ]
