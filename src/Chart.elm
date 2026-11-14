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

        values =
            List.concatMap .values config.series

        highest =
            values
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        lowest =
            values
                |> List.minimum
                |> Maybe.withDefault 0
                |> min 0

        step =
            niceStep (highest - lowest)

        topIndex =
            ceiling (highest / step)

        bottomIndex =
            floor (lowest / step)

        top =
            step * toFloat topIndex

        bottom =
            step * toFloat bottomIndex

        xOf period =
            if count <= 1 then
                50

            else
                100 * toFloat (period - 1) / toFloat (count - 1)

        yOf value =
            100 - 100 * (value - bottom) / (top - bottom)

        yTicks =
            List.range bottomIndex topIndex
                |> List.map (\index -> toFloat index * step)

        zeroLine =
            if bottomIndex < 0 then
                [ viewHorizontal "zero" yOf 0 ]

            else
                []

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
                (List.map (viewHorizontal "grid" yOf) yTicks
                    ++ zeroLine
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


{-| A round step that gives about four intervals over the given span.
-}
niceStep : Float -> Float
niceStep span =
    let
        rough =
            span / 4

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
    let
        size =
            abs value

        digits =
            if size == toFloat (round size) then
                String.fromInt (round size)

            else
                String.fromFloat size
    in
    if value < 0 then
        "−" ++ digits

    else
        digits


viewHorizontal : String -> (Float -> Float) -> Float -> Svg msg
viewHorizontal style yOf value =
    Svg.line
        [ SvgAttr.class style
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
