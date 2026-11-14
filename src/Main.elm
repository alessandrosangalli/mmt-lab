module Main exposing (main)

{-| MMT Lab: the browser front end.

The economics lives in `Model.Sim` and the accounting in `Sfc.Matrix`. This
module only holds the screen state and draws it. Interface text is in
Portuguese.

-}

import Browser
import Format
import Html exposing (Html, button, div, h1, h2, input, label, li, node, ol, p, section, span, table, tbody, td, text, tfoot, th, thead, tr)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick, onInput)
import Model.Sim as Sim exposing (Period, Policy)
import Sfc.Matrix as Matrix exposing (Sector(..))
import Style



-- STATE


type alias Model =
    { policy : Policy
    , history : List Period -- most recent first
    }


type Msg
    = SpendingChanged String
    | TaxRateChanged String
    | Advanced Int
    | Reset


initialPolicy : Policy
initialPolicy =
    { spending = 20, taxRatePct = 20 }


init : Model
init =
    { policy = initialPolicy
    , history = Sim.advanceBy 1 initialPolicy []
    }


update : Msg -> Model -> Model
update msg model =
    let
        policy =
            model.policy
    in
    case msg of
        SpendingChanged raw ->
            case String.toFloat raw of
                Just value ->
                    { model | policy = { policy | spending = value } }

                Nothing ->
                    model

        TaxRateChanged raw ->
            case String.toFloat raw of
                Just value ->
                    { model | policy = { policy | taxRatePct = value } }

                Nothing ->
                    model

        Advanced count ->
            { model | history = Sim.advanceBy count model.policy model.history }

        Reset ->
            { model | history = Sim.advanceBy 1 model.policy [] }



-- VIEW


view : Model -> Html Msg
view model =
    let
        body =
            case List.head model.history of
                Just current ->
                    div [ class "content" ]
                        [ viewSummary model.policy current
                        , viewChart model.policy model.history
                        , viewTransactions current
                        , viewBalanceSheet current
                        ]

                Nothing ->
                    p [ class "hint" ] [ text "Clique em +1 período para começar." ]
    in
    div [ class "page" ]
        [ node "style" [] [ text Style.css ]
        , viewHeader
        , viewControls model.policy
        , body
        , viewNotes
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "header" ]
        [ h1 [] [ text "Laboratório MMT" ]
        , p [ class "subtitle" ]
            [ text "Versão 0: o modelo SIM de Godley e Lavoie. Famílias, empresas e governo, e um único ativo: o dinheiro que o governo emite quando gasta." ]
        ]


type alias Slider =
    { id : String
    , caption : String
    , shown : String
    , lowest : Float
    , highest : Float
    , current : Float
    , onChange : String -> Msg
    }


viewControls : Policy -> Html Msg
viewControls policy =
    section [ class "controls" ]
        [ viewSlider
            { id = "spending"
            , caption = "Gasto público por período (G)"
            , shown = Format.decimal policy.spending
            , lowest = 0
            , highest = 50
            , current = policy.spending
            , onChange = SpendingChanged
            }
        , viewSlider
            { id = "tax-rate"
            , caption = "Alíquota de imposto (θ)"
            , shown = String.fromInt (round policy.taxRatePct) ++ "%"
            , lowest = 5
            , highest = 50
            , current = policy.taxRatePct
            , onChange = TaxRateChanged
            }
        , div [ class "buttons" ]
            [ button [ onClick (Advanced 1) ] [ text "+1 período" ]
            , button [ onClick (Advanced 10) ] [ text "+10 períodos" ]
            , button [ class "secondary", onClick Reset ] [ text "Reiniciar" ]
            ]
        ]


viewSlider : Slider -> Html Msg
viewSlider slider =
    div [ class "control" ]
        [ label [ Attr.for slider.id ]
            [ span [] [ text slider.caption ]
            , span [ class "value" ] [ text slider.shown ]
            ]
        , input
            [ Attr.id slider.id
            , Attr.type_ "range"
            , Attr.min (String.fromFloat slider.lowest)
            , Attr.max (String.fromFloat slider.highest)
            , Attr.step "1"
            , Attr.value (String.fromFloat slider.current)
            , onInput slider.onChange
            ]
            []
        ]


viewSummary : Policy -> Period -> Html Msg
viewSummary policy period =
    div [ class "summary" ]
        [ viewIndicator "Período" (String.fromInt period.number)
        , viewIndicator "PIB" (Format.decimal period.outcome.income)
        , viewIndicator "Déficit do governo" (Format.decimal period.outcome.moneyChange)
        , viewIndicator "Dinheiro das famílias" (Format.decimal period.money)
        , viewIndicator "PIB de equilíbrio (G ÷ θ)" (Format.decimal (Sim.steadyStateIncome policy))
        ]


viewIndicator : String -> String -> Html Msg
viewIndicator name amount =
    div [ class "indicator" ]
        [ span [ class "name" ] [ text name ]
        , span [ class "number" ] [ text amount ]
        ]


viewChart : Policy -> List Period -> Html Msg
viewChart policy history =
    let
        periods =
            List.reverse (List.take 30 history)

        steadyState =
            Sim.steadyStateIncome policy

        scale =
            periods
                |> List.concatMap (\period -> [ period.outcome.income, period.money ])
                |> (::) steadyState
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        percent amount =
            String.fromFloat (100 * max 0 amount / scale) ++ "%"

        viewColumn period =
            div [ class "column", Attr.title ("Período " ++ String.fromInt period.number) ]
                [ div [ class "bar income", Attr.style "height" (percent period.outcome.income) ] []
                , div [ class "bar money", Attr.style "height" (percent period.money) ] []
                ]
    in
    section [ class "block" ]
        [ h2 [] [ text "PIB e dinheiro guardado, últimos 30 períodos" ]
        , div [ class "legend" ]
            [ span [ class "key income" ] [ text "PIB" ]
            , span [ class "key money" ] [ text "Dinheiro das famílias" ]
            , span [ class "key steady" ] [ text "Equilíbrio G ÷ θ" ]
            ]
        , div [ class "chart" ]
            (div [ class "steady-line", Attr.style "bottom" (percent steadyState) ] []
                :: List.map viewColumn periods
            )
        ]


sectorName : Sector -> String
sectorName sector =
    case sector of
        Households ->
            "Famílias"

        Firms ->
            "Empresas"

        Banks ->
            "Bancos"

        Government ->
            "Governo"

        CentralBank ->
            "Banco Central"

        RestOfWorld ->
            "Resto do mundo"


viewTransactions : Period -> Html Msg
viewTransactions period =
    let
        flows =
            Sim.flows period.outcome

        matrixRows =
            Matrix.rows Sim.sectors flows

        balanced =
            Matrix.isBalanced Sim.sectors flows

        viewRow matrixRow =
            tr []
                (th [ Attr.scope "row" ] [ text matrixRow.label ]
                    :: List.map viewCell matrixRow.cells
                    ++ [ viewTotal (Matrix.rowTotal matrixRow) ]
                )

        columnTotals =
            List.map (\sector -> Matrix.columnTotal sector flows) Sim.sectors
    in
    section [ class "block" ]
        [ h2 [] [ text ("Tabela de Godley · período " ++ String.fromInt period.number) ]
        , p [ class "hint" ]
            [ text "Cada fluxo sai de um setor e entra em outro, então toda linha soma zero. As colunas somam zero quando as contas de cada setor fecham." ]
        , div [ class "scroll" ]
            [ table [ class "godley" ]
                [ viewTableHead "Transação"
                , tbody [] (List.map viewRow matrixRows)
                , tfoot []
                    [ tr []
                        (th [ Attr.scope "row" ] [ text "Σ" ]
                            :: List.map viewTotal columnTotals
                            ++ [ viewTotal (List.sum columnTotals) ]
                        )
                    ]
                ]
            ]
        , p
            [ class
                (if balanced then
                    "check ok"

                 else
                    "check error"
                )
            ]
            [ text
                (if balanced then
                    "✓ Todas as linhas e colunas fecham em zero."

                 else
                    "✗ Algo não fechou: há um erro no modelo."
                )
            ]
        ]


viewBalanceSheet : Period -> Html Msg
viewBalanceSheet period =
    section [ class "block" ]
        [ h2 [] [ text "Balanço: quem tem o quê" ]
        , div [ class "scroll" ]
            [ table [ class "godley" ]
                [ viewTableHead "Estoque"
                , tbody []
                    [ tr []
                        [ th [ Attr.scope "row" ] [ text "Dinheiro" ]
                        , viewCell (Just period.money)
                        , viewCell Nothing
                        , viewCell (Just (negate period.money))
                        , viewTotal 0
                        ]
                    ]
                ]
            ]
        , p [ class "hint" ]
            [ text "A dívida do governo e o dinheiro das famílias são o mesmo número, visto dos dois lados." ]
        ]


viewTableHead : String -> Html Msg
viewTableHead firstColumn =
    thead []
        [ tr []
            (th [] [ text firstColumn ]
                :: List.map (\sector -> th [] [ text (sectorName sector) ]) Sim.sectors
                ++ [ th [] [ text "Σ" ] ]
            )
        ]


viewCell : Maybe Float -> Html Msg
viewCell content =
    case content of
        Nothing ->
            td [ class "empty" ] []

        Just amount ->
            td
                [ class
                    (if amount < 0 then
                        "num negative"

                     else
                        "num"
                    )
                ]
                [ text (Format.signed amount) ]


viewTotal : Float -> Html Msg
viewTotal amount =
    td [ class "num total" ] [ text (Format.decimal amount) ]


viewNotes : Html Msg
viewNotes =
    section [ class "block notes" ]
        [ h2 [] [ text "O que observar" ]
        , ol []
            [ li [] [ text "No começo ninguém tem dinheiro. O governo gasta primeiro e só depois recolhe impostos." ]
            , li [] [ text "Todo déficit vira dinheiro guardado pelas famílias, centavo por centavo." ]
            , li [] [ text "O PIB caminha até G ÷ θ. Nesse ponto o déficit zera sozinho, sem ninguém decidir cortar nada." ]
            , li [] [ text "Mude o gasto ou a alíquota no meio do caminho e veja a economia buscar um novo equilíbrio." ]
            ]
        , p [ class "hint" ]
            [ text "Esta versão ainda não tem inflação, juros, bancos nem setor externo. É a contabilidade básica sobre a qual o resto vai ser construído." ]
        ]



-- PROGRAM


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
