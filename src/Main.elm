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
import Engine exposing (Snapshot)
import Format
import Html exposing (Html, a, button, div, h1, h2, input, label, li, node, ol, p, section, span, table, tbody, td, text, tfoot, th, thead, tr)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Link
import Models exposing (Info, ModelId)
import Policy exposing (Policy)
import Scenario exposing (Change, Scenario)
import Sfc.Matrix as Matrix exposing (Sector(..))
import Style



-- STATE


type alias Model =
    { modelId : ModelId
    , scenario : Scenario
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
    | InterestRate


type Msg
    = ModelSelected ModelId
    | InitialChanged Target PolicyField String
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
    ( { modelId = link.model
      , scenario = link.scenario
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
        ModelSelected modelId ->
            { model | modelId = modelId, linkVersion = Nothing }

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

        InterestRate ->
            { policy | interestRatePct = number }



-- VIEW


view : Model -> Html Msg
view model =
    let
        info =
            Models.info model.modelId

        runA =
            Models.run model.modelId model.scenario

        runB =
            Maybe.map (Models.run model.modelId) model.comparison

        at snapshots =
            List.head (List.drop (model.selected - 1) snapshots)

        comparing =
            model.comparison /= Nothing

        focus =
            case ( at runA, model.comparison, Maybe.andThen at runB ) of
                ( Just currentA, Just scenarioB, Just currentB ) ->
                    [ viewComparison info model.scenario currentA scenarioB currentB
                    , viewTransactions info "cenário A · " currentA
                    , viewTransactions info "cenário B · " currentB
                    ]

                ( Just currentA, _, _ ) ->
                    [ viewFocus info model.scenario currentA
                    , viewTransactions info "" currentA
                    , viewBalanceSheet info currentA
                    ]

                _ ->
                    [ p [ class "hint" ] [ text "Não há períodos para mostrar." ] ]

        panels =
            case model.comparison of
                Just scenarioB ->
                    [ viewScenario info Base comparing model.scenario
                    , viewScenario info Comparison comparing scenarioB
                    ]

                Nothing ->
                    [ viewScenario info Base comparing model.scenario ]
    in
    div [ class "page" ]
        ([ node "style" [] [ text Style.css ]
         , viewHeader
         , viewVersionWarning info model.linkVersion
         , viewModelPicker model.modelId
         ]
            ++ panels
            ++ [ div [ class "content" ] (viewCharts info model runA runB :: focus)
               , viewShare model
               , viewNotes info
               ]
        )


viewHeader : Html Msg
viewHeader =
    div [ class "header" ]
        [ h1 [] [ text "Laboratório MMT" ]
        , p [ class "subtitle" ]
            [ text "Modelos contábeis de Godley e Lavoie, em que todo fluxo sai de um setor e entra em outro. Monte um cenário, compare políticas e compartilhe o link." ]
        ]


viewVersionWarning : Info -> Maybe String -> Html Msg
viewVersionWarning info linkVersion =
    case linkVersion of
        Just version ->
            if version == info.version then
                text ""

            else
                p [ class "warning" ]
                    [ text
                        ("Este link foi criado com outra versão do modelo ("
                            ++ version
                            ++ "). A versão atual é "
                            ++ info.version
                            ++ ", e os números podem ser diferentes dos originais."
                        )
                    ]

        Nothing ->
            text ""


viewModelPicker : ModelId -> Html Msg
viewModelPicker selected =
    let
        viewOption id =
            button
                [ class
                    (if id == selected then
                        "model-option"

                     else
                        "model-option secondary"
                    )
                , Attr.attribute "aria-pressed"
                    (if id == selected then
                        "true"

                     else
                        "false"
                    )
                , onClick (ModelSelected id)
                ]
                [ text (Models.info id).name ]
    in
    section [ class "controls models" ]
        [ h2 [] [ text "Modelo" ]
        , div [ class "buttons" ] (List.map viewOption Models.all)
        , p [ class "hint" ] [ text (Models.info selected).summary ]
        ]


type alias Slider =
    { id : String
    , caption : String
    , shown : String
    , lowest : Float
    , highest : Float
    , step : Float
    , current : Float
    , onChange : String -> Msg
    }


viewScenario : Info -> Target -> Bool -> Scenario -> Html Msg
viewScenario info target comparing scenario =
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
                        , step = 1
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
         , viewPolicySliders info (prefix ++ "-initial") scenario.initial (InitialChanged target)
         ]
            ++ horizonSlider
            ++ [ div [ class "changes" ] (List.indexedMap (viewChange info target prefix scenario.horizon) scenario.changes)
               , div [ class "buttons" ] (addButton :: otherButtons)
               ]
        )


viewPolicySliders : Info -> String -> Policy -> (PolicyField -> String -> Msg) -> Html Msg
viewPolicySliders info prefix policy toMsg =
    let
        interestSlider =
            if info.usesInterestRate then
                [ viewSlider
                    { id = prefix ++ "-interest-rate"
                    , caption = "Taxa de juros por período (r)"
                    , shown = Format.decimal policy.interestRatePct ++ "%"
                    , lowest = 0
                    , highest = 6
                    , step = 0.5
                    , current = policy.interestRatePct
                    , onChange = toMsg InterestRate
                    }
                ]

            else
                []
    in
    div [ class "policy" ]
        ([ viewSlider
            { id = prefix ++ "-spending"
            , caption = "Gasto público por período (G)"
            , shown = Format.decimal policy.spending
            , lowest = 0
            , highest = 50
            , step = 1
            , current = policy.spending
            , onChange = toMsg Spending
            }
         , viewSlider
            { id = prefix ++ "-tax-rate"
            , caption = "Alíquota de imposto (θ)"
            , shown = String.fromInt (round policy.taxRatePct) ++ "%"
            , lowest = 5
            , highest = 50
            , step = 1
            , current = policy.taxRatePct
            , onChange = toMsg TaxRate
            }
         ]
            ++ interestSlider
        )


viewChange : Info -> Target -> String -> Int -> Int -> Change -> Html Msg
viewChange info target scenarioPrefix horizon index change =
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
            , step = 1
            , current = toFloat change.period
            , onChange = ChangePeriodChanged target index
            }
        , viewPolicySliders info prefix change.policy (ChangePolicyChanged target index)
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
            , Attr.step (String.fromFloat slider.step)
            , Attr.value (String.fromFloat slider.current)
            , onInput slider.onChange
            ]
            []
        ]


viewCharts : Info -> Model -> List Snapshot -> Maybe (List Snapshot) -> Html Msg
viewCharts info model runA runB =
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
                        Just snapshots ->
                            [ { style = "b", values = List.map pick snapshots } ]

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

        balanceSeries suffix snapshots =
            [ { style = "private" ++ suffix, values = List.map .privateSurplus snapshots }
            , { style = "government" ++ suffix, values = List.map .governmentBalance snapshots }
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

        balancesLegend =
            List.filterMap identity
                [ Just (span [ class "key private" ] [ text "Setor privado" ])
                , Just (span [ class "key government" ] [ text "Governo" ])
                , if runB /= Nothing then
                    Just (span [ class "key dashed" ] [ text "Tracejado: cenário B" ])

                  else
                    Nothing
                ]
    in
    section [ class "block" ]
        [ h2 [] [ text "PIB em cada período" ]
        , div [ class "legend" ] legend
        , chart .income
        , h2 [ class "spaced" ] [ text info.wealthLabel ]
        , chart .householdWealth
        , h2 [ class "spaced" ] [ text "Saldos setoriais" ]
        , div [ class "legend" ] balancesLegend
        , balancesChart
        , p [ class "hint" ]
            [ text "As duas curvas são espelhadas: em cada período, o superávit do setor privado é igual ao déficit do governo. Nestes modelos não há setor externo." ]
        , viewSlider
            { id = "selected-period"
            , caption = "Período em foco"
            , shown = String.fromInt model.selected
            , lowest = 1
            , highest = toFloat model.scenario.horizon
            , step = 1
            , current = toFloat model.selected
            , onChange = PeriodSlid
            }
        ]


policySentence : Info -> Policy -> String
policySentence info policy =
    "gasto de "
        ++ Format.decimal policy.spending
        ++ (if info.usesInterestRate then
                ", alíquota de "
                    ++ String.fromInt (round policy.taxRatePct)
                    ++ "% e juro de "
                    ++ Format.decimal policy.interestRatePct
                    ++ "%"

            else
                " e alíquota de "
                    ++ String.fromInt (round policy.taxRatePct)
                    ++ "%"
           )


steadyStateText : Maybe Float -> String
steadyStateText income =
    case income of
        Just value ->
            Format.decimal value

        Nothing ->
            "não há"


viewFocus : Info -> Scenario -> Snapshot -> Html Msg
viewFocus info scenario snapshot =
    let
        policy =
            Scenario.policyAt scenario snapshot.number
    in
    section [ class "block" ]
        [ h2 [] [ text ("Período " ++ String.fromInt snapshot.number) ]
        , div [ class "summary" ]
            (List.map (\indicator -> viewIndicator indicator.name (Format.decimal indicator.value)) snapshot.indicators
                ++ [ viewIndicator "PIB de equilíbrio" (steadyStateText (info.steadyStateIncome policy)) ]
            )
        , p [ class "hint" ] [ text ("Política em vigor neste período: " ++ policySentence info policy ++ ".") ]
        ]


viewIndicator : String -> String -> Html Msg
viewIndicator name amount =
    div [ class "indicator" ]
        [ span [ class "name" ] [ text name ]
        , span [ class "number" ] [ text amount ]
        ]


viewComparison : Info -> Scenario -> Snapshot -> Scenario -> Snapshot -> Html Msg
viewComparison info scenarioA snapshotA scenarioB snapshotB =
    let
        policyA =
            Scenario.policyAt scenarioA snapshotA.number

        policyB =
            Scenario.policyAt scenarioB snapshotB.number

        steadyA =
            info.steadyStateIncome policyA

        steadyB =
            info.steadyStateIncome policyB

        viewRow name cellA cellB difference =
            tr []
                [ th [ Attr.scope "row" ] [ text name ]
                , td [ class "num" ] [ text cellA ]
                , td [ class "num" ] [ text cellB ]
                , td [ class "num total" ] [ text difference ]
                ]

        viewIndicatorRow left right =
            viewRow left.name
                (Format.decimal left.value)
                (Format.decimal right.value)
                (Format.signed (right.value - left.value))
    in
    section [ class "block" ]
        [ h2 [] [ text ("Período " ++ String.fromInt snapshotA.number ++ ": os dois cenários") ]
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
                    (List.map2 viewIndicatorRow snapshotA.indicators snapshotB.indicators
                        ++ [ viewRow "PIB de equilíbrio"
                                (steadyStateText steadyA)
                                (steadyStateText steadyB)
                                (Maybe.map2 (\left right -> Format.signed (right - left)) steadyA steadyB
                                    |> Maybe.withDefault ""
                                )
                           ]
                    )
                ]
            ]
        , p [ class "hint" ]
            [ text
                ("Política em vigor neste período. Cenário A: "
                    ++ policySentence info policyA
                    ++ ". Cenário B: "
                    ++ policySentence info policyB
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


viewTransactions : Info -> String -> Snapshot -> Html Msg
viewTransactions info scenarioLabel snapshot =
    let
        matrixRows =
            Matrix.rows info.sectors snapshot.flows

        balanced =
            Matrix.isBalanced info.sectors snapshot.flows

        columnTotals =
            List.map (\sector -> Matrix.columnTotal sector snapshot.flows) info.sectors
    in
    section [ class "block" ]
        [ h2 [] [ text ("Tabela de Godley · " ++ scenarioLabel ++ "período " ++ String.fromInt snapshot.number) ]
        , p [ class "hint" ]
            [ text "Cada fluxo sai de um setor e entra em outro, então toda linha soma zero. As colunas somam zero quando as contas de cada setor fecham." ]
        , div [ class "scroll" ]
            [ table [ class "godley" ]
                [ viewTableHead info.sectors "Transação"
                , tbody [] (List.map viewMatrixRow matrixRows)
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


viewBalanceSheet : Info -> Snapshot -> Html Msg
viewBalanceSheet info snapshot =
    let
        netWorth =
            List.map (\sector -> Matrix.columnTotal sector snapshot.stocks) info.sectors
    in
    section [ class "block" ]
        [ h2 [] [ text "Balanço: quem tem o quê" ]
        , div [ class "scroll" ]
            [ table [ class "godley" ]
                [ viewTableHead info.sectors "Estoque"
                , tbody [] (List.map viewMatrixRow (Matrix.rows info.sectors snapshot.stocks))
                , tfoot []
                    [ tr []
                        (th [ Attr.scope "row" ] [ text "Riqueza financeira líquida" ]
                            :: List.map viewTotal netWorth
                            ++ [ viewTotal (List.sum netWorth) ]
                        )
                    ]
                ]
            ]
        , p [ class "hint" ]
            [ text "Todo ativo de um setor é a dívida de outro. Por isso a riqueza financeira de todos os setores, somada, é zero." ]
        ]


viewMatrixRow : Matrix.Row -> Html Msg
viewMatrixRow matrixRow =
    tr []
        (th [ Attr.scope "row" ] [ text matrixRow.label ]
            :: List.map viewCell matrixRow.cells
            ++ [ viewTotal (Matrix.rowTotal matrixRow) ]
        )


viewTableHead : List Sector -> String -> Html Msg
viewTableHead sectors firstColumn =
    thead []
        [ tr []
            (th [] [ text firstColumn ]
                :: List.map (\sector -> th [] [ text (sectorName sector) ]) sectors
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
            "?" ++ Link.toQuery model.modelId model.scenario model.comparison model.selected
    in
    section [ class "block share" ]
        [ h2 [] [ text "Link deste cenário" ]
        , p [ class "hint" ]
            [ text "Este endereço reproduz exatamente o que está na tela: o modelo, os cenários, as mudanças de política, o número de períodos e o período em foco." ]
        , input
            [ Attr.id "share-link"
            , Attr.type_ "text"
            , Attr.readonly True
            , Attr.value (model.baseUrl ++ query)
            ]
            []
        , p [] [ a [ Attr.href query ] [ text "Abrir este cenário pelo link" ] ]
        ]


viewNotes : Info -> Html Msg
viewNotes info =
    section [ class "block notes" ]
        [ h2 [] [ text "O que observar" ]
        , ol [] (List.map (\note -> li [] [ text note ]) info.notes)
        , p [ class "hint" ]
            [ text "Estes modelos ainda não têm inflação, bancos nem setor externo. São a contabilidade básica sobre a qual o resto vai ser construído." ]
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
