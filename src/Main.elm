module Main exposing (main)

{-| MMT Lab: the browser front end.

The economics lives in `Model.Sim`, the accounting in `Sfc.Matrix` and the
experiment in `Scenario`. This module holds the screen state and draws it.
The page never writes to the address bar: it reads the scenario from the URL
once, at start-up, and shows a link that reproduces the current state.
Interface text is in Portuguese.

-}

import Browser
import Format
import Html exposing (Html, a, button, div, h1, h2, input, label, li, node, ol, p, section, span, table, tbody, td, text, tfoot, th, thead, tr)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Link
import Model.Sim as Sim exposing (Period, Policy)
import Scenario exposing (Change, Scenario)
import Sfc.Matrix as Matrix exposing (Sector(..))
import Style



-- STATE


type alias Model =
    { scenario : Scenario
    , selected : Int
    , linkVersion : Maybe String
    , baseUrl : String
    }


type PolicyField
    = Spending
    | TaxRate


type Msg
    = InitialChanged PolicyField String
    | HorizonChanged String
    | ChangeAdded
    | ChangeRemoved Int
    | ChangePeriodChanged Int String
    | ChangePolicyChanged Int PolicyField String
    | PeriodSelected Int
    | PeriodSlid String
    | Reset


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        link =
            Link.fromQuery (stringFlag "search" flags)
    in
    ( { scenario = link.scenario
      , selected = link.selected
      , linkVersion = link.version
      , baseUrl = stringFlag "base" flags
      }
    , Cmd.none
    )


stringFlag : String -> Decode.Value -> String
stringFlag name flags =
    Decode.decodeValue (Decode.field name Decode.string) flags
        |> Result.withDefault ""


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( normalize (apply msg model), Cmd.none )


normalize : Model -> Model
normalize model =
    let
        scenario =
            Scenario.sanitize model.scenario
    in
    { model
        | scenario = scenario
        , selected = clamp 1 scenario.horizon model.selected
    }


apply : Msg -> Model -> Model
apply msg model =
    let
        scenario =
            model.scenario
    in
    case msg of
        InitialChanged field raw ->
            case String.toFloat raw of
                Just number ->
                    { model | scenario = { scenario | initial = setField field number scenario.initial } }

                Nothing ->
                    model

        HorizonChanged raw ->
            case String.toInt raw of
                Just horizon ->
                    { model
                        | scenario = { scenario | horizon = horizon }
                        , selected =
                            if model.selected == scenario.horizon then
                                horizon

                            else
                                model.selected
                    }

                Nothing ->
                    model

        ChangeAdded ->
            if List.length scenario.changes >= Scenario.maxChanges then
                model

            else
                let
                    latest =
                        scenario.changes
                            |> List.map .period
                            |> List.maximum
                            |> Maybe.withDefault 0

                    period =
                        clamp 2 scenario.horizon (latest + 10)

                    current =
                        Scenario.policyAt scenario period

                    added =
                        { period = period
                        , policy = { current | spending = min 50 (current.spending + 5) }
                        }
                in
                { model
                    | scenario = { scenario | changes = scenario.changes ++ [ added ] }
                    , selected = scenario.horizon
                }

        ChangeRemoved index ->
            { model | scenario = { scenario | changes = removeAt index scenario.changes } }

        ChangePeriodChanged index raw ->
            case String.toInt raw of
                Just period ->
                    { model
                        | scenario =
                            { scenario
                                | changes = updateAt index (\change -> { change | period = period }) scenario.changes
                            }
                    }

                Nothing ->
                    model

        ChangePolicyChanged index field raw ->
            case String.toFloat raw of
                Just number ->
                    { model
                        | scenario =
                            { scenario
                                | changes =
                                    updateAt index
                                        (\change -> { change | policy = setField field number change.policy })
                                        scenario.changes
                            }
                    }

                Nothing ->
                    model

        PeriodSelected period ->
            { model | selected = period }

        PeriodSlid raw ->
            case String.toInt raw of
                Just period ->
                    { model | selected = period }

                Nothing ->
                    model

        Reset ->
            { model
                | scenario = Scenario.default
                , selected = Scenario.default.horizon
                , linkVersion = Nothing
            }


setField : PolicyField -> Float -> Policy -> Policy
setField field number policy =
    case field of
        Spending ->
            { policy | spending = number }

        TaxRate ->
            { policy | taxRatePct = number }


updateAt : Int -> (item -> item) -> List item -> List item
updateAt index change items =
    List.indexedMap
        (\position item ->
            if position == index then
                change item

            else
                item
        )
        items


removeAt : Int -> List item -> List item
removeAt index items =
    List.take index items ++ List.drop (index + 1) items



-- VIEW


view : Model -> Html Msg
view model =
    let
        periods =
            Scenario.run model.scenario

        body =
            case List.head (List.drop (model.selected - 1) periods) of
                Just current ->
                    div [ class "content" ]
                        [ viewChart model.scenario model.selected periods
                        , viewFocus model.scenario current
                        , viewTransactions current
                        , viewBalanceSheet current
                        ]

                Nothing ->
                    p [ class "hint" ] [ text "Não há períodos para mostrar." ]
    in
    div [ class "page" ]
        [ node "style" [] [ text Style.css ]
        , viewHeader
        , viewVersionWarning model.linkVersion
        , viewScenario model.scenario
        , body
        , viewShare model
        , viewNotes
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "header" ]
        [ h1 [] [ text "Laboratório MMT" ]
        , p [ class "subtitle" ]
            [ text "O modelo SIM de Godley e Lavoie. Famílias, empresas e governo, e um único ativo: o dinheiro que o governo emite quando gasta." ]
        ]


viewVersionWarning : Maybe String -> Html Msg
viewVersionWarning linkVersion =
    case linkVersion of
        Just version ->
            if version == Link.modelVersion then
                text ""

            else
                p [ class "warning" ]
                    [ text
                        ("Este link foi criado com outra versão do modelo ("
                            ++ version
                            ++ "). A versão atual é "
                            ++ Link.modelVersion
                            ++ ", e os números podem ser diferentes dos originais."
                        )
                    ]

        Nothing ->
            text ""


type alias Slider =
    { id : String
    , caption : String
    , shown : String
    , lowest : Float
    , highest : Float
    , current : Float
    , onChange : String -> Msg
    }


viewScenario : Scenario -> Html Msg
viewScenario scenario =
    section [ class "controls" ]
        [ h2 [] [ text "Cenário" ]
        , viewPolicySliders "initial" scenario.initial InitialChanged
        , viewSlider
            { id = "horizon"
            , caption = "Número de períodos"
            , shown = String.fromInt scenario.horizon
            , lowest = toFloat Scenario.minHorizon
            , highest = toFloat Scenario.maxHorizon
            , current = toFloat scenario.horizon
            , onChange = HorizonChanged
            }
        , div [ class "changes" ] (List.indexedMap (viewChange scenario.horizon) scenario.changes)
        , div [ class "buttons" ]
            [ button
                [ onClick ChangeAdded
                , Attr.disabled (List.length scenario.changes >= Scenario.maxChanges)
                ]
                [ text "Adicionar mudança de política" ]
            , button [ class "secondary", onClick Reset ] [ text "Reiniciar" ]
            ]
        ]


viewPolicySliders : String -> Policy -> (PolicyField -> String -> Msg) -> Html Msg
viewPolicySliders prefix policy toMsg =
    div [ class "policy" ]
        [ viewSlider
            { id = prefix ++ "-spending"
            , caption = "Gasto público por período (G)"
            , shown = Format.decimal policy.spending
            , lowest = 0
            , highest = 50
            , current = policy.spending
            , onChange = toMsg Spending
            }
        , viewSlider
            { id = prefix ++ "-tax-rate"
            , caption = "Alíquota de imposto (θ)"
            , shown = String.fromInt (round policy.taxRatePct) ++ "%"
            , lowest = 5
            , highest = 50
            , current = policy.taxRatePct
            , onChange = toMsg TaxRate
            }
        ]


viewChange : Int -> Int -> Change -> Html Msg
viewChange horizon index change =
    let
        prefix =
            "change-" ++ String.fromInt index
    in
    div [ class "change" ]
        [ div [ class "change-head" ]
            [ span [] [ text ("Mudança " ++ String.fromInt (index + 1)) ]
            , button [ class "secondary small", onClick (ChangeRemoved index) ] [ text "Remover" ]
            ]
        , viewSlider
            { id = prefix ++ "-period"
            , caption = "A partir do período"
            , shown = String.fromInt change.period
            , lowest = 2
            , highest = toFloat horizon
            , current = toFloat change.period
            , onChange = ChangePeriodChanged index
            }
        , viewPolicySliders prefix change.policy (ChangePolicyChanged index)
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


viewChart : Scenario -> Int -> List Period -> Html Msg
viewChart scenario selected periods =
    let
        scale =
            periods
                |> List.concatMap (\period -> [ period.outcome.income, period.money ])
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        percent amount =
            String.fromFloat (100 * max 0 amount / scale) ++ "%"

        changePeriods =
            List.map .period scenario.changes

        columnClass number =
            String.join " "
                (List.filterMap identity
                    [ Just "column"
                    , if number == selected then
                        Just "selected"

                      else
                        Nothing
                    , if List.member number changePeriods then
                        Just "changed"

                      else
                        Nothing
                    ]
                )

        viewColumn period =
            div
                [ class (columnClass period.number)
                , Attr.title ("Período " ++ String.fromInt period.number)
                , onClick (PeriodSelected period.number)
                ]
                [ div [ class "bar income", Attr.style "height" (percent period.outcome.income) ] []
                , div [ class "bar money", Attr.style "height" (percent period.money) ] []
                ]
    in
    section [ class "block" ]
        [ h2 [] [ text "PIB e dinheiro guardado em cada período" ]
        , div [ class "legend" ]
            [ span [ class "key income" ] [ text "PIB" ]
            , span [ class "key money" ] [ text "Dinheiro das famílias" ]
            , span [ class "key changed" ] [ text "Mudança de política" ]
            ]
        , div [ class "chart" ] (List.map viewColumn periods)
        , viewSlider
            { id = "selected-period"
            , caption = "Período em foco"
            , shown = String.fromInt selected
            , lowest = 1
            , highest = toFloat scenario.horizon
            , current = toFloat selected
            , onChange = PeriodSlid
            }
        ]


viewFocus : Scenario -> Period -> Html Msg
viewFocus scenario period =
    let
        policy =
            Scenario.policyAt scenario period.number
    in
    section [ class "block" ]
        [ h2 [] [ text ("Período " ++ String.fromInt period.number) ]
        , div [ class "summary" ]
            [ viewIndicator "PIB" (Format.decimal period.outcome.income)
            , viewIndicator "Déficit do governo" (Format.decimal period.outcome.moneyChange)
            , viewIndicator "Dinheiro das famílias" (Format.decimal period.money)
            , viewIndicator "PIB de equilíbrio (G ÷ θ)" (Format.decimal (Sim.steadyStateIncome policy))
            ]
        , p [ class "hint" ]
            [ text
                ("Política em vigor neste período: gasto de "
                    ++ Format.decimal policy.spending
                    ++ " e alíquota de "
                    ++ String.fromInt (round policy.taxRatePct)
                    ++ "%."
                )
            ]
        ]


viewIndicator : String -> String -> Html Msg
viewIndicator name amount =
    div [ class "indicator" ]
        [ span [ class "name" ] [ text name ]
        , span [ class "number" ] [ text amount ]
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


viewShare : Model -> Html Msg
viewShare model =
    let
        query =
            "?" ++ Link.toQuery model.scenario model.selected
    in
    section [ class "block share" ]
        [ h2 [] [ text "Link deste cenário" ]
        , p [ class "hint" ]
            [ text "Este endereço reproduz exatamente o que está na tela: a política, as mudanças, o número de períodos e o período em foco." ]
        , input
            [ Attr.id "share-link"
            , Attr.type_ "text"
            , Attr.readonly True
            , Attr.value (model.baseUrl ++ query)
            ]
            []
        , p [] [ a [ Attr.href query ] [ text "Abrir este cenário pelo link" ] ]
        ]


viewNotes : Html Msg
viewNotes =
    section [ class "block notes" ]
        [ h2 [] [ text "O que observar" ]
        , ol []
            [ li [] [ text "No começo ninguém tem dinheiro. O governo gasta primeiro e só depois recolhe impostos." ]
            , li [] [ text "Todo déficit vira dinheiro guardado pelas famílias, centavo por centavo." ]
            , li [] [ text "O PIB caminha até G ÷ θ. Nesse ponto o déficit zera sozinho, sem ninguém decidir cortar nada." ]
            , li [] [ text "Adicione uma mudança de política e veja a economia buscar um novo equilíbrio a partir daquele período." ]
            ]
        , p [ class "hint" ]
            [ text "Este modelo ainda não tem inflação, juros, bancos nem setor externo. É a contabilidade básica sobre a qual o resto vai ser construído." ]
        ]



-- PROGRAM


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
