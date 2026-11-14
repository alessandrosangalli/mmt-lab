module Chart exposing (Config, Series, view)

{-| A responsive line chart.

The lines are drawn in an SVG that stretches to any width, and the axis
labels and the dots are HTML laid over it, so text keeps its size on a phone
and on a desktop alike.

-}

import Html exposing (Html, div, text)
import Html.Attributes as Attr exposing (class)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Svg.Events


{-| One line. `style` is a CSS class that sets its colour and dash.
-}
type alias Series =
    { style : String
    , values : List Float
    }


type alias Config msg =
    { series : List Series
    , markers : List Int
    , selected : Int
    , onSelect : Int -> msg
    }


view : Config msg -> Html msg
view config =
    let
        count =
            config.series
                |> List.map (\series -> List.length series.values)
                |> List.maximum
                |> Maybe.withDefault 0

        highest =
            config.series
                |> List.concatMap .values
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        step =
            niceStep highest

        top =
            step * toFloat (ceiling (highest / step))

        xOf period =
            if count <= 1 then
                50

            else
                100 * toFloat (period - 1) / toFloat (count - 1)

        yOf value =
            100 - 100 * value / top

        yTicks =
            List.range 0 (round (top / step))
                |> List.map (\index -> toFloat index * step)

        valueAtSelected series =
            series.values
                |> List.drop (config.selected - 1)
                |> List.head
                |> Maybe.map (\value -> ( series.style, value ))
    in
    div [ class "linechart" ]
        [ div [ class "plot" ]
            (Svg.svg
                [ SvgAttr.viewBox "0 0 100 100"
                , SvgAttr.preserveAspectRatio "none"
                ]
                (List.map (viewGridLine yOf) yTicks
                    ++ List.map (viewVertical "marker" xOf) config.markers
                    ++ [ viewVertical "cursor" xOf config.selected ]
                    ++ List.map (viewSeries xOf yOf) config.series
                    ++ List.map (viewHitArea count xOf config.onSelect) (List.range 1 count)
                )
                :: List.map (viewYTick yOf) yTicks
                ++ List.map (viewXTick xOf) (xTicks count)
                ++ List.map (viewDot (xOf config.selected) yOf) (List.filterMap valueAtSelected config.series)
            )
        ]


{-| A round step that gives about four intervals up to the highest value.
-}
niceStep : Float -> Float
niceStep highest =
    let
        rough =
            highest / 4

        magnitude =
            10 ^ toFloat (floor (logBase 10 rough))

        normalized =
            rough / magnitude
    in
    if normalized <= 1 then
        magnitude

    else if normalized <= 2 then
        2 * magnitude

    else if normalized <= 5 then
        5 * magnitude

    else
        10 * magnitude


xTicks : Int -> List Int
xTicks count =
    let
        step =
            if count <= 20 then
                5

            else if count <= 60 then
                10

            else
                20
    in
    1 :: List.filter (\period -> modBy step period == 0) (List.range 2 count)


percent : Float -> String
percent value =
    String.fromFloat value ++ "%"


tickLabel : Float -> String
tickLabel value =
    if value == toFloat (round value) then
        String.fromInt (round value)

    else
        String.fromFloat value


viewGridLine : (Float -> Float) -> Float -> Svg msg
viewGridLine yOf value =
    Svg.line
        [ SvgAttr.class "grid"
        , SvgAttr.x1 "0"
        , SvgAttr.x2 "100"
        , SvgAttr.y1 (String.fromFloat (yOf value))
        , SvgAttr.y2 (String.fromFloat (yOf value))
        ]
        []


viewVertical : String -> (Int -> Float) -> Int -> Svg msg
viewVertical style xOf period =
    Svg.line
        [ SvgAttr.class style
        , SvgAttr.x1 (String.fromFloat (xOf period))
        , SvgAttr.x2 (String.fromFloat (xOf period))
        , SvgAttr.y1 "0"
        , SvgAttr.y2 "100"
        ]
        []


viewSeries : (Int -> Float) -> (Float -> Float) -> Series -> Svg msg
viewSeries xOf yOf series =
    let
        point index value =
            String.fromFloat (xOf (index + 1)) ++ "," ++ String.fromFloat (yOf value)
    in
    Svg.polyline
        [ SvgAttr.class ("series " ++ series.style)
        , SvgAttr.points (String.join " " (List.indexedMap point series.values))
        ]
        []


{-| An invisible column over each period, so a tap anywhere selects it.
-}
viewHitArea : Int -> (Int -> Float) -> (Int -> msg) -> Int -> Svg msg
viewHitArea count xOf onSelect period =
    let
        width =
            if count <= 1 then
                100

            else
                100 / toFloat (count - 1)
    in
    Svg.rect
        [ SvgAttr.class "hit"
        , SvgAttr.x (String.fromFloat (xOf period - width / 2))
        , SvgAttr.y "0"
        , SvgAttr.width (String.fromFloat width)
        , SvgAttr.height "100"
        , Svg.Events.onClick (onSelect period)
        ]
        []


viewYTick : (Float -> Float) -> Float -> Html msg
viewYTick yOf value =
    div [ class "ytick", Attr.style "top" (percent (yOf value)) ] [ text (tickLabel value) ]


viewXTick : (Int -> Float) -> Int -> Html msg
viewXTick xOf period =
    div [ class "xtick", Attr.style "left" (percent (xOf period)) ] [ text (String.fromInt period) ]


viewDot : Float -> (Float -> Float) -> ( String, Float ) -> Html msg
viewDot x yOf ( style, value ) =
    div
        [ class ("dot " ++ style)
        , Attr.style "left" (percent x)
        , Attr.style "top" (percent (yOf value))
        ]
        []
