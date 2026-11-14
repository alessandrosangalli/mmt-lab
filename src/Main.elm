module Main exposing (main)

{-| MMT Lab: the browser front end.

The economics lives in the `Model.*` modules, the accounting in `Sfc.Matrix`
and the experiment in `Scenario`. This module holds the screen state and
draws whatever snapshots the chosen model produces.
The page never writes to the address bar: it reads the scenario from the URL
once, at start-up, and shows a link that reproduces the current state.
Interface text is in Portuguese.

-}

import Browser
import Chart
import Dict
import Engine exposing (Snapshot)
import Format
import Html exposing (Html, a, button, div, h1, h2, h3, input, label, li, node, ol, option, p, section, select, span, table, tbody, td, text, tfoot, th, thead, tr)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Link
import Models exposing (Info, ModelId, SteadyState(..))
import Multiverse exposing (Cell, Outcome(..))
import Policy exposing (Policy)
import Premise exposing (Premise, Premises)
import Process
import Scenario exposing (Change, Scenario)
import Sfc.Matrix as Matrix exposing (Sector(..))
import Style
import Task



-- STATE


type alias Model =
    { modelId : ModelId
    , scenario : Scenario
    , comparison : Maybe Scenario
    , selected : Int
    , linkVersion : Maybe String
    , baseUrl : String
    , mapAxes : Axes
    , map : MapState
    }


{-| The keys of the two premises the map varies.
-}
type alias Axes =
    { horizontal : String
    , vertical : String
    }


{-| A map being computed, or already computed. `basis` is the scenario it was
computed for, without the two premises it varies. `pending` are the vertical
values still to run, and `rows` the lines done so far, top line first.
-}
type alias MapJob =
    { axes : Axes
    , basis : Scenario
    , pending : List Float
    , rows : List (List Cell)
    }


type MapState
    = NoMap
    | Mapping MapJob
    | Mapped MapJob


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
    | PremiseChanged Target String String
    | ComparisonAdded
    | ComparisonRemoved
    | PeriodSelected Int
    | PeriodSlid String
    | Reset
    | MapAxisChanged Bool String
    | MapRequested
    | MapTick
    | MapCellChosen Float Float


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        link =
            Link.fromQuery (stringFlag "search" flags)
    in
    ( normalize
        { modelId = link.model
        , scenario = link.scenario
        , comparison = link.comparison
        , selected = link.selected
        , linkVersion = link.version
        , baseUrl = stringFlag "base" flags
        , mapAxes = { horizontal = "", vertical = "" }
        , map = NoMap
        }
    , Cmd.none
    )


stringFlag : String -> Decode.Value -> String
stringFlag name flags =
    Decode.decodeValue (Decode.field name Decode.string) flags
        |> Result.withDefault ""


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        next =
            normalize (apply msg model)
    in
    case next.map of
        Mapping _ ->
            ( next, Task.perform (\_ -> MapTick) (Process.sleep 10) )

        _ ->
            ( next, Cmd.none )


{-| Keep every value in range, the premises within what the chosen model
knows, and the two scenarios on the same time axis.
-}
normalize : Model -> Model
normalize model =
    let
        known =
            (Models.info model.modelId).premises

        clean dirty =
            let
                sanitized =
                    Scenario.sanitize dirty
            in
            { sanitized | premises = Premise.sanitize known sanitized.premises }

        scenario =
            clean model.scenario

        alignHorizon other =
            clean { other | horizon = scenario.horizon }
    in
    { model
        | scenario = scenario
        , comparison = Maybe.map alignHorizon model.comparison
        , selected = clamp 1 scenario.horizon model.selected
        , mapAxes = validAxes known model.mapAxes
    }


{-| Axes naming two different premises of the model, falling back to its
first two.
-}
validAxes : List Premise -> Axes -> Axes
validAxes known axes =
    let
        keys =
            List.map .key known

        isKnown key =
            List.member key keys
    in
    if isKnown axes.horizontal && isKnown axes.vertical && axes.horizontal /= axes.vertical then
        axes

    else
        case keys of
            first :: second :: _ ->
                { horizontal = first, vertical = second }

            _ ->
                { horizontal = "", vertical = "" }


findPremise : String -> List Premise -> Maybe Premise
findPremise key known =
    List.head (List.filter (\premise -> premise.key == key) known)


{-| The scenario a map is computed for: everything but the two premises the
map itself varies.
-}
basisOf : Axes -> Scenario -> Scenario
basisOf axes scenario =
    { scenario
        | premises =
            scenario.premises
                |> Dict.remove axes.horizontal
                |> Dict.remove axes.vertical
    }


apply : Msg -> Model -> Model
apply msg model =
    case msg of
        ModelSelected modelId ->
            startOver modelId model

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

        PremiseChanged target key raw ->
            case String.toFloat raw of
                Just number ->
                    edit target (\scenario -> { scenario | premises = Dict.insert key number scenario.premises }) model

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
            startOver model.modelId model

        MapAxisChanged isHorizontal key ->
            let
                axes =
                    model.mapAxes

                other =
                    if isHorizontal then
                        axes.vertical

                    else
                        axes.horizontal
            in
            if key == other then
                { model | mapAxes = { horizontal = axes.vertical, vertical = axes.horizontal } }

            else if isHorizontal then
                { model | mapAxes = { axes | horizontal = key } }

            else
                { model | mapAxes = { axes | vertical = key } }

        MapRequested ->
            case findPremise model.mapAxes.vertical (Models.info model.modelId).premises of
                Just vertical ->
                    { model
                        | map =
                            Mapping
                                { axes = model.mapAxes
                                , basis = basisOf model.mapAxes model.scenario
                                , pending = List.reverse (Multiverse.axisValues vertical)
                                , rows = []
                                }
                    }

                Nothing ->
                    model

        MapTick ->
            case model.map of
                Mapping job ->
                    advanceMap job model

                _ ->
                    model

        MapCellChosen x y ->
            case model.map of
                Mapped job ->
                    edit Base
                        (\scenario ->
                            { scenario
                                | premises =
                                    scenario.premises
                                        |> Dict.insert job.axes.horizontal x
                                        |> Dict.insert job.axes.vertical y
                            }
                        )
                        model

                _ ->
                    model


{-| Compute one more line of the map. The job is dropped if the scenario it
was started for has changed in the meantime.
-}
advanceMap : MapJob -> Model -> Model
advanceMap job model =
    let
        known =
            (Models.info model.modelId).premises
    in
    if job.basis /= basisOf job.axes model.scenario then
        { model | map = NoMap }

    else
        case ( job.pending, findPremise job.axes.horizontal known, findPremise job.axes.vertical known ) of
            ( y :: rest, Just horizontal, Just vertical ) ->
                let
                    line =
                        Multiverse.row (Models.run model.modelId) job.basis horizontal vertical y

                    updated =
                        { job | pending = rest, rows = job.rows ++ [ line ] }
                in
                if List.isEmpty rest then
                    { model | map = Mapped updated }

                else
                    { model | map = Mapping updated }

            _ ->
                { model | map = Mapped job }


{-| Each model starts from its own default scenario, so choosing a model
discards the scenario on screen.
-}
startOver : ModelId -> Model -> Model
startOver modelId model =
    let
        scenario =
            Models.defaultScenario modelId
    in
    { model
        | modelId = modelId
        , scenario = scenario
        , comparison = Nothing
        , selected = scenario.horizon
        , linkVersion = Nothing
        , map = NoMap
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

        snapshotsA =
            runA.snapshots

        snapshotsB =
            Maybe.map .snapshots runB

        at snapshots =
            List.head (List.drop (model.selected - 1) snapshots)

        failures =
            List.filterMap identity
                [ Maybe.map
                    (viewFailure
                        (if comparing then
                            "No cenário A, o"

                         else
                            "O"
                        )
                    )
                    runA.failedAt
                , runB
                    |> Maybe.andThen .failedAt
                    |> Maybe.map (viewFailure "No cenário B, o")
                ]

        comparing =
            model.comparison /= Nothing

        focus =
            case ( at snapshotsA, model.comparison, Maybe.andThen at snapshotsB ) of
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
                    [ p [ class "hint" ] [ text "Não há resultado para o período em foco. Escolha um período anterior." ] ]

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
            ++ failures
            ++ [ div [ class "content" ] (viewCharts info model snapshotsA snapshotsB :: focus)
               , viewMap info model
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


viewFailure : String -> Int -> Html Msg
viewFailure opening period =
    p [ class "warning" ]
        [ text
            (opening
                ++ " modelo deixa de ter solução no período "
                ++ String.fromInt period
                ++ ". Os resultados param no período anterior. Isso acontece quando a política leva a economia para fora do alcance em que as equações do modelo fazem sentido."
            )
        ]


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
        , p [ class "hint" ] [ text "Trocar de modelo reinicia o cenário." ]
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

        premiseControls =
            if List.isEmpty info.premises then
                []

            else
                [ div [ class "premises" ]
                    (h3 [] [ text "Premissas do modelo" ]
                        :: List.map (viewPremise target prefix scenario.premises) info.premises
                    )
                ]

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
            ++ premiseControls
        )


viewPremise : Target -> String -> Premises -> Premise -> Html Msg
viewPremise target prefix premises premise =
    let
        current =
            Premise.value premise premises
    in
    div [ class "premise" ]
        [ viewSlider
            { id = prefix ++ "-premise-" ++ premise.key
            , caption = premise.name
            , shown = Format.fixed 2 current
            , lowest = premise.lowest
            , highest = premise.highest
            , step = premise.step
            , current = current
            , onChange = PremiseChanged target premise.key
            }
        , p [ class "premise-note" ] [ text premise.note ]
        ]


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
                ++ (if info.hasForeignSector then
                        [ { style = "foreign" ++ suffix, values = List.map .foreignBalance snapshots } ]

                    else
                        []
                   )

        extraValue index snapshot =
            snapshot.charts
                |> List.drop index
                |> List.head
                |> Maybe.map .value
                |> Maybe.withDefault 0

        extraCharts =
            List.head runA
                |> Maybe.map .charts
                |> Maybe.withDefault []
                |> List.indexedMap
                    (\index extra ->
                        [ h2 [ class "spaced" ] [ text extra.name ]
                        , chart (extraValue index)
                        ]
                    )
                |> List.concat

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
                , if info.hasForeignSector then
                    Just (span [ class "key foreign" ] [ text "Exterior" ])

                  else
                    Nothing
                , if runB /= Nothing then
                    Just (span [ class "key dashed" ] [ text "Tracejado: cenário B" ])

                  else
                    Nothing
                ]
    in
    section [ class "block" ]
        ([ h2 [] [ text info.incomeLabel ]
         , div [ class "legend" ] legend
         , chart .income
         ]
            ++ extraCharts
            ++ [ h2 [ class "spaced" ] [ text info.wealthLabel ]
               , chart .householdWealth
               , h2 [ class "spaced" ] [ text "Saldos setoriais" ]
               , div [ class "legend" ] balancesLegend
               , balancesChart
               , p [ class "hint" ]
                    [ text
                        (if info.hasForeignSector then
                            "O que cada setor poupou no período. Os três saldos somam zero: se o governo e o exterior poupam, o setor privado se endivida na mesma medida."

                         else
                            "As duas curvas são espelhadas: em cada período, o superávit do setor privado é igual ao déficit do governo. Neste modelo não há setor externo."
                        )
                    ]
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
        )


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


steadyStateText : SteadyState -> Maybe String
steadyStateText steadyState =
    case steadyState of
        SettlesAt income ->
            Just (Format.decimal income)

        NeverSettles ->
            Just "não há"

        NotComputed ->
            Nothing


viewFocus : Info -> Scenario -> Snapshot -> Html Msg
viewFocus info scenario snapshot =
    let
        policy =
            Scenario.policyAt scenario snapshot.number
    in
    section [ class "block" ]
        [ h2 [] [ text ("Período " ++ String.fromInt snapshot.number) ]
        , div [ class "summary" ]
            (List.map (\indicator -> viewIndicator indicator.name (Format.indicator indicator.value)) snapshot.indicators
                ++ (case steadyStateText (info.steadyStateIncome policy) of
                        Just shown ->
                            [ viewIndicator "PIB de equilíbrio" shown ]

                        Nothing ->
                            []
                   )
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
                (Format.indicator left.value)
                (Format.indicator right.value)
                (Format.signedIndicator (right.value - left.value))

        steadyRow =
            case ( steadyA, steadyB ) of
                ( SettlesAt left, SettlesAt right ) ->
                    [ viewRow "PIB de equilíbrio" (Format.decimal left) (Format.decimal right) (Format.signed (right - left)) ]

                ( NotComputed, _ ) ->
                    []

                ( _, NotComputed ) ->
                    []

                _ ->
                    [ viewRow "PIB de equilíbrio"
                        (steadyStateText steadyA |> Maybe.withDefault "")
                        (steadyStateText steadyB |> Maybe.withDefault "")
                        ""
                    ]
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
                    (List.map2 viewIndicatorRow snapshotA.indicators snapshotB.indicators ++ steadyRow)
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


viewMap : Info -> Model -> Html Msg
viewMap info model =
    case ( findPremise model.mapAxes.horizontal info.premises, findPremise model.mapAxes.vertical info.premises ) of
        ( Just horizontal, Just vertical ) ->
            let
                viewChoice current premise =
                    option [ Attr.value premise.key, Attr.selected (premise.key == current) ] [ text premise.name ]

                viewAxisPicker id caption isHorizontal current =
                    div [ class "map-axis" ]
                        [ label [ Attr.for id ] [ text caption ]
                        , select [ Attr.id id, onInput (MapAxisChanged isHorizontal) ]
                            (List.map (viewChoice current) info.premises)
                        ]

                busy =
                    case model.map of
                        Mapping _ ->
                            True

                        _ ->
                            False
            in
            section [ class "block map" ]
                ([ h2 [] [ text "Mapa de premissas" ]
                 , p [ class "hint" ]
                    [ text "Um resultado que vale para um único conjunto de parâmetros diz pouco. O mapa roda o cenário A para cada combinação de duas premissas e mostra como a economia termina em cada uma. A política e as outras premissas ficam como estão no cenário A." ]
                 , div [ class "map-controls" ]
                    [ viewAxisPicker "map-horizontal" "Na horizontal" True model.mapAxes.horizontal
                    , viewAxisPicker "map-vertical" "Na vertical" False model.mapAxes.vertical
                    , button [ onClick MapRequested, Attr.disabled busy ]
                        [ text
                            (if busy then
                                "Calculando…"

                             else
                                "Calcular o mapa"
                            )
                        ]
                    ]
                 ]
                    ++ viewMapResult info model
                )

        _ ->
            text ""


viewMapResult : Info -> Model -> List (Html Msg)
viewMapResult info model =
    let
        show job finished =
            case ( findPremise job.axes.horizontal info.premises, findPremise job.axes.vertical info.premises ) of
                ( Just horizontal, Just vertical ) ->
                    let
                        stale =
                            finished && job.basis /= basisOf job.axes model.scenario
                    in
                    [ p [ class "map-axis-name" ] [ text ("↑ " ++ vertical.name) ]
                    , viewMapGrid model.scenario.premises horizontal vertical job finished
                    , p [ class "map-axis-name across" ] [ text (horizontal.name ++ " →") ]
                    , div [ class "legend" ]
                        [ span [ class "key settles" ] [ text "Estabiliza" ]
                        , span [ class "key adjusting" ] [ text "Ainda se ajustando no último período" ]
                        , span [ class "key failed" ] [ text "Sem solução (o número é o período)" ]
                        , span [ class "key here" ] [ text "Cenário A" ]
                        ]
                    , p [ class "hint" ]
                        [ text
                            (if stale then
                                "O cenário A mudou depois do cálculo. Calcule o mapa de novo."

                             else if finished then
                                "Toque em um quadrado para levar essas duas premissas ao cenário A."

                             else
                                "Calculando uma linha por vez."
                            )
                        ]
                    ]

                _ ->
                    []
    in
    case model.map of
        NoMap ->
            []

        Mapping job ->
            show job False

        Mapped job ->
            show job True


viewMapGrid : Premises -> Premise -> Premise -> MapJob -> Bool -> Html Msg
viewMapGrid premises horizontal vertical job finished =
    let
        xs =
            Multiverse.axisValues horizontal

        ys =
            List.reverse (Multiverse.axisValues vertical)

        halfStep premise =
            (premise.highest - premise.lowest) / toFloat (Multiverse.steps - 1) / 2

        isHere cell =
            (abs (cell.x - Premise.value horizontal premises) < halfStep horizontal)
                && (abs (cell.y - Premise.value vertical premises) < halfStep vertical)

        describe outcome =
            case outcome of
                Settles ->
                    "estabiliza"

                StillAdjusting ->
                    "ainda se ajustando no último período"

                NoSolution period ->
                    "sem solução a partir do período " ++ String.fromInt period

        viewMapCell cell =
            let
                ( style, content ) =
                    case cell.outcome of
                        Settles ->
                            ( "settles", "" )

                        StillAdjusting ->
                            ( "adjusting", "" )

                        NoSolution period ->
                            ( "failed", String.fromInt period )
            in
            button
                [ class
                    ("cell "
                        ++ style
                        ++ (if isHere cell then
                                " here"

                            else
                                ""
                           )
                    )
                , Attr.disabled (not finished)
                , Attr.title
                    (horizontal.name
                        ++ " "
                        ++ Format.fixed 2 cell.x
                        ++ ", "
                        ++ vertical.name
                        ++ " "
                        ++ Format.fixed 2 cell.y
                        ++ ": "
                        ++ describe cell.outcome
                    )
                , onClick (MapCellChosen cell.x cell.y)
                ]
                [ text content ]

        viewLine y line =
            div [ class "map-tick" ] [ text (Format.fixed 2 y) ]
                :: (case line of
                        Just cells ->
                            List.map viewMapCell cells

                        Nothing ->
                            List.map (\_ -> div [ class "cell pending" ] []) xs
                   )

        lines =
            List.indexedMap (\index y -> viewLine y (List.head (List.drop index job.rows))) ys
    in
    div [ class "map-grid" ]
        (List.concat lines
            ++ (div [ class "map-tick" ] [] :: List.map (\x -> div [ class "map-tick below" ] [ text (Format.fixed 2 x) ]) xs)
        )


viewShare : Model -> Html Msg
viewShare model =
    let
        query =
            "?" ++ Link.toQuery model.modelId model.scenario model.comparison model.selected
    in
    section [ class "block share" ]
        [ h2 [] [ text "Link deste cenário" ]
        , p [ class "hint" ]
            [ text "Este endereço reproduz exatamente o que está na tela: o modelo, os cenários, as mudanças de política, as premissas, o número de períodos e o período em foco." ]
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
            [ text "Os parâmetros destes modelos são os do livro. Eles mostram como a contabilidade funciona, e não são uma descrição da economia brasileira." ]
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
