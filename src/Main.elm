module Main exposing (main)

{-| MMT Lab: the browser front end.

The economics lives in `Model.Sim`, the accounting in `Sfc.Matrix` and the
experiment in `Scenario`. This module holds the screen state and draws it.
The page never writes to the address bar: it reads the scenario from the URL
once, at start-up, and shows a link that reproduces the current state.
Interface text is in Portuguese.

-}

import Browser
import Chart
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
    , comparison : Maybe Scenario
    , selected : Int
    , linkVersion : Maybe String
    , baseUrl : String
    }


{-| Which of the two scenarios an edit applies to.
-}
type Target
    = Base
    | Comparison


type PolicyField
    = Spending
    | TaxRate


type Msg
    = InitialChanged Target PolicyField String
    | HorizonChanged String
    | ChangeAdded Target
    | ChangeRemoved Target Int
    | ChangePeriodChanged Target Int String
    | ChangePolicyChanged Target Int PolicyField String
    | ComparisonAdded
    | ComparisonRemoved
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
      , comparison = link.comparison
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


{-| Keep every value in range and the two scenarios on the same time axis.
-}
normalize : Model -> Model
normalize model =
    let
        scenario =
            Scenario.sanitize model.scenario

        alignHorizon other =
            Scenario.sanitize { other | horizon = scenario.horizon }
    in
    { model
        | scenario = scenario
        , comparison = Maybe.map alignHorizon model.comparison
        , selected = clamp 1 scenario.horizon model.selected
    }


apply : Msg -> Model -> Model
apply msg model =
    case msg of
        InitialChanged target field raw ->
            case String.toFloat raw of
                Just number ->
                    edit target (\scenario -> { scenario | initial = setField field number scenario.initial }) model

                Nothing ->
                    model

        HorizonChanged raw ->
            case String.toInt raw of
                Just horizon ->
                    let
                        scenario =
                            model.scenario
                    in
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

        ChangeAdded target ->
            edit target Scenario.addChange model

        ChangeRemoved target index ->
            edit target (Scenario.removeChange index) model

        ChangePeriodChanged target index raw ->
            case String.toInt raw of
                Just period ->
                    edit target (Scenario.updateChange index (\change -> { change | period = period })) model

                Nothing ->
                    model

        ChangePolicyChanged target index field raw ->
            case String.toFloat raw of
                Just number ->
                    edit target
                        (Scenario.updateChange index (\change -> { change | policy = setField field number change.policy }))
                        model

                Nothing ->
                    model

        ComparisonAdded ->
            { model | comparison = Just model.scenario }

        ComparisonRemoved ->
            { model | comparison = Nothing }

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
                , comparison = Nothing
                , selected = Scenario.default.horizon
                , linkVersion = Nothing
            }


edit : Target -> (Scenario -> Scenario) -> Model -> Model
edit target change model =
    case target of
        Base ->
            { model | scenario = change model.scenario }

        Comparison ->
            { model | comparison = Maybe.map change model.comparison }


setField : PolicyField -> Float -> Policy -> Policy
setField field number policy =
    case field of
        Spending ->
            { policy | spending = number }

        TaxRate ->
            { policy | taxRatePct = number }



-- VIEW


view : Model -> Html Msg
view model =
    let
        runA =
            Scenario.run model.scenario

        runB =
            Maybe.map Scenario.run model.comparison

        at periods =
            List.head (List.drop (model.selected - 1) periods)

        comparing =
            model.comparison /= Nothing

        focus =
            case ( at runA, model.comparison, Maybe.andThen at runB ) of
                ( Just currentA, Just scenarioB, Just currentB ) ->
                    [ viewComparison model.scenario currentA scenarioB currentB
                    , viewTransactions "cenário A · " currentA
                    , viewTransactions "cenário B · " currentB
                    ]

                ( Just currentA, _, _ ) ->
                    [ viewFocus model.scenario currentA
                    , viewTransactions "" currentA
                    , viewBalanceSheet currentA
                    ]

                _ ->
                    [ p [ class "hint" ] [ text "Não há períodos para mostrar." ] ]

        panels =
            case model.comparison of
                Just scenarioB ->
                    [ viewScenario Base comparing model.scenario
                    , viewScenario Comparison comparing scenarioB
                    ]

                Nothing ->
                    [ viewScenario Base comparing model.scenario ]
    in
    div [ class "page" ]
        ([ node "style" [] [ text Style.css ]
         , viewHeader
         , viewVersionWarning model.linkVersion
         ]
            ++ panels
            ++ [ div [ class "content" ] (viewCharts model runA runB :: focus)
               , viewShare model
               , viewNotes
               ]
        )


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


viewScenario : Target -> Bool -> Scenario -> Html Msg
viewScenario target comparing scenario =
    let
        prefix =
            case target of
                Base ->
                    "a"

                Comparison ->
                    "b"

        title =
            case ( target, comparing ) of
                ( Base, False ) ->
                    "Cenário"

                ( Base, True ) ->
                    "Cenário A"

                ( Comparison, _ ) ->
                    "Cenário B"

        horizonSlider =
            case target of
                Base ->
                    [ viewSlider
                        { id = "horizon"
                        , caption =
                            if comparing then
                                "Número de períodos (vale para os dois cenários)"

                            else
                                "Número de períodos"
                        , shown = String.fromInt scenario.horizon
                        , lowest = toFloat Scenario.minHorizon
                        , highest = toFloat Scenario.maxHorizon
                        , current = toFloat scenario.horizon
                        , onChange = HorizonChanged
                        }
                    ]

                Comparison ->
                    []

        addButton =
            button
                [ onClick (ChangeAdded target)
                , Attr.disabled (List.length scenario.changes >= Scenario.maxChanges)
                ]
                [ text "Adicionar mudança de política" ]

        otherButtons =
            case ( target, comparing ) of
                ( Base, False ) ->
                    [ button [ class "secondary", onClick ComparisonAdded ] [ text "Comparar com outro cenário" ]
                    , button [ class "secondary", onClick Reset ] [ text "Reiniciar" ]
                    ]

                ( Base, True ) ->
                    [ button [ class "secondary", onClick Reset ] [ text "Reiniciar" ] ]

                ( Comparison, _ ) ->
                    [ button [ class "secondary", onClick ComparisonRemoved ] [ text "Remover o cenário B" ] ]
    in
    section [ class ("controls " ++ prefix) ]
        ([ h2 [] [ text title ]
         , viewPolicySliders (prefix ++ "-initial") scenario.initial (InitialChanged target)
         ]
            ++ horizonSlider
            ++ [ div [ class "changes" ] (List.indexedMap (viewChange target prefix scenario.horizon) scenario.changes)
               , div [ class "buttons" ] (addButton :: otherButtons)
               ]
        )


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


viewChange : Target -> String -> Int -> Int -> Change -> Html Msg
viewChange target scenarioPrefix horizon index change =
    let
        prefix =
            scenarioPrefix ++ "-change-" ++ String.fromInt index
    in
    div [ class "change" ]
        [ div [ class "change-head" ]
            [ span [] [ text ("Mudança " ++ String.fromInt (index + 1)) ]
            , button [ class "secondary small", onClick (ChangeRemoved target index) ] [ text "Remover" ]
            ]
        , viewSlider
            { id = prefix ++ "-period"
            , caption = "A partir do período"
            , shown = String.fromInt change.period
            , lowest = 2
            , highest = toFloat horizon
            , current = toFloat change.period
            , onChange = ChangePeriodChanged target index
            }
        , viewPolicySliders prefix change.policy (ChangePolicyChanged target index)
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


viewCharts : Model -> List Period -> Maybe (List Period) -> Html Msg
viewCharts model runA runB =
    let
        markers =
            List.map .period model.scenario.changes
                ++ (model.comparison
                        |> Maybe.map (\scenario -> List.map .period scenario.changes)
                        |> Maybe.withDefault []
                   )

        seriesOf pick =
            { style = "a", values = List.map pick runA }
                :: (case runB of
                        Just periods ->
                            [ { style = "b", values = List.map pick periods } ]

                        Nothing ->
                            []
                   )

        chart pick =
            Chart.view
                { series = seriesOf pick
                , markers = markers
                , selected = model.selected
                , onSelect = PeriodSelected
                }

        privateSurplus period =
            period.outcome.disposableIncome - period.outcome.consumption

        governmentBalance period =
            period.outcome.taxes - period.outcome.spending

        balanceSeries suffix periods =
            [ { style = "private" ++ suffix, values = List.map privateSurplus periods }
            , { style = "government" ++ suffix, values = List.map governmentBalance periods }
            ]

        balancesChart =
            Chart.view
                { series =
                    balanceSeries "" runA
                        ++ (runB
                                |> Maybe.map (balanceSeries " dashed")
                                |> Maybe.withDefault []
                           )
                , markers = markers
                , selected = model.selected
                , onSelect = PeriodSelected
                }

        balancesLegend =
            List.filterMap identity
                [ Just (span [ class "key private" ] [ text "Setor privado" ])
                , Just (span [ class "key government" ] [ text "Governo" ])
                , if runB /= Nothing then
                    Just (span [ class "key dashed" ] [ text "Tracejado: cenário B" ])

                  else
                    Nothing
                ]

        legend =
            List.filterMap identity
                [ if runB /= Nothing then
                    Just (span [ class "key a" ] [ text "Cenário A" ])

                  else
                    Nothing
                , if runB /= Nothing then
                    Just (span [ class "key b" ] [ text "Cenário B" ])

                  else
                    Nothing
                , if List.isEmpty markers then
                    Nothing

                  else
                    Just (span [ class "key changed" ] [ text "Mudança de política" ])
                , Just (span [ class "key cursor" ] [ text "Período em foco" ])
                ]
    in
    section [ class "block" ]
        [ h2 [] [ text "PIB em cada período" ]
        , div [ class "legend" ] legend
        , chart (\period -> period.outcome.income)
        , h2 [ class "spaced" ] [ text "Dinheiro guardado pelas famílias" ]
        , chart .money
        , h2 [ class "spaced" ] [ text "Saldos setoriais" ]
        , div [ class "legend" ] balancesLegend
        , balancesChart
        , p [ class "hint" ]
            [ text "As duas curvas são espelhadas: em cada período, o superávit do setor privado é igual ao déficit do governo. Neste modelo, as empresas ficam sempre em zero e não há setor externo." ]
        , viewSlider
            { id = "selected-period"
            , caption = "Período em foco"
            , shown = String.fromInt model.selected
            , lowest = 1
            , highest = toFloat model.scenario.horizon
            , current = toFloat model.selected
            , onChange = PeriodSlid
            }
        ]


policySentence : Policy -> String
policySentence policy =
    "gasto de "
        ++ Format.decimal policy.spending
        ++ " e alíquota de "
        ++ String.fromInt (round policy.taxRatePct)
        ++ "%"


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
        , p [ class "hint" ] [ text ("Política em vigor neste período: " ++ policySentence policy ++ ".") ]
        ]


viewIndicator : String -> String -> Html Msg
viewIndicator name amount =
    div [ class "indicator" ]
        [ span [ class "name" ] [ text name ]
        , span [ class "number" ] [ text amount ]
        ]


viewComparison : Scenario -> Period -> Scenario -> Period -> Html Msg
viewComparison scenarioA periodA scenarioB periodB =
    let
        policyA =
            Scenario.policyAt scenarioA periodA.number

        policyB =
            Scenario.policyAt scenarioB periodB.number

        viewRow name valueA valueB =
            tr []
                [ th [ Attr.scope "row" ] [ text name ]
                , td [ class "num" ] [ text (Format.decimal valueA) ]
                , td [ class "num" ] [ text (Format.decimal valueB) ]
                , td [ class "num total" ] [ text (Format.signed (valueB - valueA)) ]
                ]
    in
    section [ class "block" ]
        [ h2 [] [ text ("Período " ++ String.fromInt periodA.number ++ ": os dois cenários") ]
        , div [ class "scroll" ]
            [ table [ class "godley" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Indicador" ]
                        , th [] [ text "Cenário A" ]
                        , th [] [ text "Cenário B" ]
                        , th [] [ text "B − A" ]
                        ]
                    ]
                , tbody []
                    [ viewRow "PIB" periodA.outcome.income periodB.outcome.income
                    , viewRow "Déficit do governo" periodA.outcome.moneyChange periodB.outcome.moneyChange
                    , viewRow "Dinheiro das famílias" periodA.money periodB.money
                    , viewRow "PIB de equilíbrio (G ÷ θ)" (Sim.steadyStateIncome policyA) (Sim.steadyStateIncome policyB)
                    ]
                ]
            ]
        , p [ class "hint" ]
            [ text
                ("Política em vigor neste período. Cenário A: "
                    ++ policySentence policyA
                    ++ ". Cenário B: "
                    ++ policySentence policyB
                    ++ "."
                )
            ]
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


viewTransactions : String -> Period -> Html Msg
viewTransactions scenarioLabel period =
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
        [ h2 [] [ text ("Tabela de Godley · " ++ scenarioLabel ++ "período " ++ String.fromInt period.number) ]
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
            "?" ++ Link.toQuery model.scenario model.comparison model.selected
    in
    section [ class "block share" ]
        [ h2 [] [ text "Link deste cenário" ]
        , p [ class "hint" ]
            [ text "Este endereço reproduz exatamente o que está na tela: os cenários, as mudanças de política, o número de períodos e o período em foco." ]
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
            , li [] [ text "Compare dois cenários: um corte de gasto e um aumento de imposto levam a equilíbrios diferentes, e o gráfico mostra o caminho de cada um." ]
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
