module Main exposing (main)

{- Laboratório MMT, versão 0

   Modelo SIM de Godley e Lavoie (2007, "Monetary Economics", cap. 3).
   Três setores (famílias, empresas e governo) e um único ativo:
   o dinheiro que o governo emite quando gasta.

   Todo o modelo é a função pura `passo`: recebe a política e o dinheiro
   que as famílias tinham, e devolve os fluxos do período.
-}

import Browser
import Html exposing (Html, button, div, h1, h2, input, label, li, node, ol, p, section, span, table, tbody, td, text, tfoot, th, thead, tr)
import Html.Attributes as Attr exposing (class)
import Html.Events exposing (onClick, onInput)



-- COMPORTAMENTO DAS FAMÍLIAS (fixo nesta versão)


{-| Fração da renda disponível que as famílias gastam a cada período.
-}
propensaoRenda : Float
propensaoRenda =
    0.6


{-| Fração do dinheiro guardado que as famílias gastam a cada período.
-}
propensaoRiqueza : Float
propensaoRiqueza =
    0.4



-- TIPOS


type alias Politica =
    { gasto : Float
    , aliquotaPct : Float
    }


type alias Fluxos =
    { renda : Float
    , consumo : Float
    , gasto : Float
    , impostos : Float
    , rendaDisponivel : Float
    , variacaoDinheiro : Float
    }


type alias Periodo =
    { numero : Int
    , dinheiro : Float
    , fluxos : Fluxos
    }


type alias Model =
    { politica : Politica
    , historico : List Periodo -- o mais recente vem primeiro
    }


type Msg
    = MudouGasto String
    | MudouAliquota String
    | Avancar Int
    | Reiniciar



-- O MODELO ECONÔMICO


aliquota : Politica -> Float
aliquota politica =
    politica.aliquotaPct / 100


{-| Um período da economia.

    Y  = C + G                       (o PIB é tudo o que se gasta)
    T  = θ · Y                       (impostos sobre a renda)
    YD = Y − T                       (renda disponível)
    C  = α1 · YD + α2 · H(anterior)  (consumo)
    ΔH = YD − C  =  G − T            (o déficit vira dinheiro das famílias)

Substituindo C na primeira equação, o PIB sai direto:
Y = (G + α2 · H) / (1 − α1 · (1 − θ))

-}
passo : Politica -> Float -> Fluxos
passo politica dinheiroAnterior =
    let
        theta =
            aliquota politica

        renda =
            (politica.gasto + propensaoRiqueza * dinheiroAnterior)
                / (1 - propensaoRenda * (1 - theta))

        impostos =
            theta * renda

        rendaDisponivel =
            renda - impostos

        consumo =
            propensaoRenda * rendaDisponivel + propensaoRiqueza * dinheiroAnterior
    in
    { renda = renda
    , consumo = consumo
    , gasto = politica.gasto
    , impostos = impostos
    , rendaDisponivel = rendaDisponivel
    , variacaoDinheiro = rendaDisponivel - consumo
    }


avancar : Politica -> List Periodo -> List Periodo
avancar politica historico =
    let
        ( numeroAnterior, dinheiroAnterior ) =
            case historico of
                ultimo :: _ ->
                    ( ultimo.numero, ultimo.dinheiro )

                [] ->
                    ( 0, 0 )

        fluxos =
            passo politica dinheiroAnterior
    in
    { numero = numeroAnterior + 1
    , dinheiro = dinheiroAnterior + fluxos.variacaoDinheiro
    , fluxos = fluxos
    }
        :: historico


avancarVarios : Int -> Politica -> List Periodo -> List Periodo
avancarVarios n politica historico =
    if n <= 0 then
        historico

    else
        avancarVarios (n - 1) politica (avancar politica historico)


{-| Onde a economia para: o déficit zera quando T = G, ou seja, θ · Y = G.
-}
pibDeEquilibrio : Politica -> Float
pibDeEquilibrio politica =
    politica.gasto / aliquota politica



-- TABELA DE GODLEY


type alias Linha =
    { transacao : String
    , familias : Maybe Float
    , empresas : Maybe Float
    , governo : Maybe Float
    }


linhasDeGodley : Fluxos -> List Linha
linhasDeGodley f =
    [ Linha "Consumo" (Just (negate f.consumo)) (Just f.consumo) Nothing
    , Linha "Gasto público" Nothing (Just f.gasto) (Just (negate f.gasto))
    , Linha "Salários" (Just f.renda) (Just (negate f.renda)) Nothing
    , Linha "Impostos" (Just (negate f.impostos)) Nothing (Just f.impostos)
    , Linha "Variação do dinheiro" (Just (negate f.variacaoDinheiro)) Nothing (Just f.variacaoDinheiro)
    ]


somaDaLinha : Linha -> Float
somaDaLinha linha =
    List.sum (List.filterMap identity [ linha.familias, linha.empresas, linha.governo ])


somaDaColuna : (Linha -> Maybe Float) -> List Linha -> Float
somaDaColuna setor linhas =
    List.sum (List.filterMap setor linhas)


fechaEmZero : List Linha -> Bool
fechaEmZero linhas =
    let
        quaseZero x =
            abs x < 0.000000001

        somas =
            List.map somaDaLinha linhas
                ++ [ somaDaColuna .familias linhas
                   , somaDaColuna .empresas linhas
                   , somaDaColuna .governo linhas
                   ]
    in
    List.all quaseZero somas



-- INICIALIZAÇÃO E ATUALIZAÇÃO


politicaInicial : Politica
politicaInicial =
    { gasto = 20, aliquotaPct = 20 }


init : Model
init =
    { politica = politicaInicial
    , historico = avancarVarios 1 politicaInicial []
    }


update : Msg -> Model -> Model
update msg model =
    let
        politica =
            model.politica
    in
    case msg of
        MudouGasto texto ->
            case String.toFloat texto of
                Just valor ->
                    { model | politica = { politica | gasto = valor } }

                Nothing ->
                    model

        MudouAliquota texto ->
            case String.toFloat texto of
                Just valor ->
                    { model | politica = { politica | aliquotaPct = valor } }

                Nothing ->
                    model

        Avancar quantos ->
            { model | historico = avancarVarios quantos model.politica model.historico }

        Reiniciar ->
            { model | historico = avancarVarios 1 model.politica [] }



-- TELA


view : Model -> Html Msg
view model =
    let
        corpo =
            case List.head model.historico of
                Just atual ->
                    div [ class "conteudo" ]
                        [ viewResumo model.politica atual
                        , viewGrafico model.politica model.historico
                        , viewTabela atual
                        , viewBalanco atual
                        ]

                Nothing ->
                    p [ class "explica" ] [ text "Clique em +1 período para começar." ]
    in
    div [ class "pagina" ]
        [ node "style" [] [ text estilo ]
        , cabecalho
        , viewControles model.politica
        , corpo
        , viewNotas
        ]


cabecalho : Html Msg
cabecalho =
    div [ class "cabecalho" ]
        [ h1 [] [ text "Laboratório MMT" ]
        , p [ class "subtitulo" ]
            [ text "Versão 0: o modelo SIM de Godley e Lavoie. Famílias, empresas e governo, e um único ativo: o dinheiro que o governo emite quando gasta." ]
        ]


type alias Controle =
    { id : String
    , rotulo : String
    , valorExibido : String
    , minimo : Float
    , maximo : Float
    , valor : Float
    , aoMudar : String -> Msg
    }


viewControles : Politica -> Html Msg
viewControles politica =
    section [ class "controles" ]
        [ controle
            { id = "gasto"
            , rotulo = "Gasto público por período (G)"
            , valorExibido = formatar politica.gasto
            , minimo = 0
            , maximo = 50
            , valor = politica.gasto
            , aoMudar = MudouGasto
            }
        , controle
            { id = "aliquota"
            , rotulo = "Alíquota de imposto (θ)"
            , valorExibido = String.fromInt (round politica.aliquotaPct) ++ "%"
            , minimo = 5
            , maximo = 50
            , valor = politica.aliquotaPct
            , aoMudar = MudouAliquota
            }
        , div [ class "botoes" ]
            [ button [ onClick (Avancar 1) ] [ text "+1 período" ]
            , button [ onClick (Avancar 10) ] [ text "+10 períodos" ]
            , button [ class "secundario", onClick Reiniciar ] [ text "Reiniciar" ]
            ]
        ]


controle : Controle -> Html Msg
controle c =
    div [ class "controle" ]
        [ label [ Attr.for c.id ]
            [ span [] [ text c.rotulo ]
            , span [ class "valor" ] [ text c.valorExibido ]
            ]
        , input
            [ Attr.id c.id
            , Attr.type_ "range"
            , Attr.min (String.fromFloat c.minimo)
            , Attr.max (String.fromFloat c.maximo)
            , Attr.step "1"
            , Attr.value (String.fromFloat c.valor)
            , onInput c.aoMudar
            ]
            []
        ]


viewResumo : Politica -> Periodo -> Html Msg
viewResumo politica periodo =
    div [ class "resumo" ]
        [ indicador "Período" (String.fromInt periodo.numero)
        , indicador "PIB" (formatar periodo.fluxos.renda)
        , indicador "Déficit do governo" (formatar periodo.fluxos.variacaoDinheiro)
        , indicador "Dinheiro das famílias" (formatar periodo.dinheiro)
        , indicador "PIB de equilíbrio (G ÷ θ)" (formatar (pibDeEquilibrio politica))
        ]


indicador : String -> String -> Html Msg
indicador nome valor =
    div [ class "indicador" ]
        [ span [ class "nome" ] [ text nome ]
        , span [ class "numero" ] [ text valor ]
        ]


viewGrafico : Politica -> List Periodo -> Html Msg
viewGrafico politica historico =
    let
        periodos =
            List.reverse (List.take 30 historico)

        equilibrio =
            pibDeEquilibrio politica

        escala =
            periodos
                |> List.concatMap (\per -> [ per.fluxos.renda, per.dinheiro ])
                |> (::) equilibrio
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        altura valor =
            Attr.style "height" (String.fromFloat (100 * max 0 valor / escala) ++ "%")

        coluna per =
            div [ class "coluna", Attr.title ("Período " ++ String.fromInt per.numero) ]
                [ div [ class "barra pib", altura per.fluxos.renda ] []
                , div [ class "barra dinheiro", altura per.dinheiro ] []
                ]
    in
    section [ class "bloco" ]
        [ h2 [] [ text "PIB e dinheiro guardado, últimos 30 períodos" ]
        , div [ class "legenda" ]
            [ span [ class "chave pib" ] [ text "PIB" ]
            , span [ class "chave dinheiro" ] [ text "Dinheiro das famílias" ]
            , span [ class "chave equilibrio" ] [ text "Equilíbrio G ÷ θ" ]
            ]
        , div [ class "grafico" ]
            (div
                [ class "linha-equilibrio"
                , Attr.style "bottom" (String.fromFloat (100 * equilibrio / escala) ++ "%")
                ]
                []
                :: List.map coluna periodos
            )
        ]


viewTabela : Periodo -> Html Msg
viewTabela periodo =
    let
        linhas =
            linhasDeGodley periodo.fluxos

        fecha =
            fechaEmZero linhas

        linhaHtml linha =
            tr []
                [ th [ Attr.scope "row" ] [ text linha.transacao ]
                , celula linha.familias
                , celula linha.empresas
                , celula linha.governo
                , celulaSoma (somaDaLinha linha)
                ]
    in
    section [ class "bloco" ]
        [ h2 [] [ text ("Tabela de Godley · período " ++ String.fromInt periodo.numero) ]
        , p [ class "explica" ]
            [ text "Cada fluxo sai de um setor e entra em outro. Por isso toda linha soma zero, e toda coluna também." ]
        , div [ class "rolagem" ]
            [ table [ class "godley" ]
                [ cabecalhoDaTabela "Transação"
                , tbody [] (List.map linhaHtml linhas)
                , tfoot []
                    [ tr []
                        [ th [ Attr.scope "row" ] [ text "Σ" ]
                        , celulaSoma (somaDaColuna .familias linhas)
                        , celulaSoma (somaDaColuna .empresas linhas)
                        , celulaSoma (somaDaColuna .governo linhas)
                        , celulaSoma (List.sum (List.map somaDaLinha linhas))
                        ]
                    ]
                ]
            ]
        , p
            [ class
                (if fecha then
                    "verificacao ok"

                 else
                    "verificacao erro"
                )
            ]
            [ text
                (if fecha then
                    "✓ Todas as linhas e colunas fecham em zero."

                 else
                    "✗ Algo não fechou: há um erro no modelo."
                )
            ]
        ]


viewBalanco : Periodo -> Html Msg
viewBalanco periodo =
    section [ class "bloco" ]
        [ h2 [] [ text "Balanço: quem tem o quê" ]
        , div [ class "rolagem" ]
            [ table [ class "godley" ]
                [ cabecalhoDaTabela "Estoque"
                , tbody []
                    [ tr []
                        [ th [ Attr.scope "row" ] [ text "Dinheiro" ]
                        , celula (Just periodo.dinheiro)
                        , celula Nothing
                        , celula (Just (negate periodo.dinheiro))
                        , celulaSoma (periodo.dinheiro - periodo.dinheiro)
                        ]
                    ]
                ]
            ]
        , p [ class "explica" ]
            [ text "A dívida do governo e o dinheiro das famílias são o mesmo número, visto dos dois lados." ]
        ]


cabecalhoDaTabela : String -> Html Msg
cabecalhoDaTabela primeira =
    thead []
        [ tr []
            [ th [] [ text primeira ]
            , th [] [ text "Famílias" ]
            , th [] [ text "Empresas" ]
            , th [] [ text "Governo" ]
            , th [] [ text "Σ" ]
            ]
        ]


celula : Maybe Float -> Html Msg
celula conteudo =
    case conteudo of
        Nothing ->
            td [ class "vazia" ] []

        Just v ->
            td
                [ class
                    (if v < 0 then
                        "num negativo"

                     else
                        "num"
                    )
                ]
                [ text (formatarComSinal v) ]


celulaSoma : Float -> Html Msg
celulaSoma v =
    td [ class "num soma" ] [ text (formatar v) ]


viewNotas : Html Msg
viewNotas =
    section [ class "bloco notas" ]
        [ h2 [] [ text "O que observar" ]
        , ol []
            [ li [] [ text "No começo ninguém tem dinheiro. O governo gasta primeiro e só depois recolhe impostos." ]
            , li [] [ text "Todo déficit vira dinheiro guardado pelas famílias, centavo por centavo." ]
            , li [] [ text "O PIB caminha até G ÷ θ. Nesse ponto o déficit zera sozinho, sem ninguém decidir cortar nada." ]
            , li [] [ text "Mude o gasto ou a alíquota no meio do caminho e veja a economia buscar um novo equilíbrio." ]
            ]
        , p [ class "explica" ]
            [ text "Esta versão ainda não tem inflação, juros, bancos nem setor externo. É a contabilidade básica sobre a qual o resto vai ser construído." ]
        ]



-- FORMATAÇÃO (padrão brasileiro: vírgula decimal)


formatar : Float -> String
formatar x =
    let
        decimos =
            round (abs x * 10)

        sinal =
            if x < 0 && decimos /= 0 then
                "−"

            else
                ""
    in
    sinal ++ String.fromInt (decimos // 10) ++ "," ++ String.fromInt (modBy 10 decimos)


formatarComSinal : Float -> String
formatarComSinal x =
    if x > 0 && round (x * 10) /= 0 then
        "+" ++ formatar x

    else
        formatar x



-- ESTILO


estilo : String
estilo =
    """
:root {
  --fundo: #eef2ee;
  --folha: #f8faf7;
  --tinta: #16242a;
  --apagado: #5a6a6b;
  --regua: #cfd9d3;
  --azul: #1f5fa6;
  --vermelho: #b3342b;
  --ambar: #a8741a;
}
@media (prefers-color-scheme: dark) {
  :root {
    --fundo: #0f1719;
    --folha: #162225;
    --tinta: #e2eae5;
    --apagado: #95a6a4;
    --regua: #2b3c3f;
    --azul: #74aae6;
    --vermelho: #ef7d70;
    --ambar: #e0aa4f;
    color-scheme: dark;
  }
}
body {
  margin: 0;
  background: var(--fundo);
  color: var(--tinta);
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}
.pagina {
  max-width: 860px;
  margin: 0 auto;
  padding: 24px 16px 48px;
  display: grid;
  gap: 22px;
}
h1 {
  font-family: Georgia, "Times New Roman", serif;
  font-size: 1.9rem;
  margin: 0;
}
.subtitulo {
  margin: 6px 0 0;
  color: var(--apagado);
  max-width: 62ch;
  line-height: 1.5;
}
.controles {
  background: var(--folha);
  border: 1px solid var(--regua);
  border-radius: 10px;
  padding: 16px;
  display: grid;
  gap: 14px;
}
.controle label {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 0.9rem;
  margin-bottom: 4px;
}
.valor { font-variant-numeric: tabular-nums; font-weight: 600; }
input[type=range] { width: 100%; accent-color: var(--azul); }
.botoes { display: flex; flex-wrap: wrap; gap: 8px; }
button {
  font: inherit;
  font-weight: 600;
  padding: 9px 14px;
  border-radius: 8px;
  border: 1px solid var(--azul);
  background: var(--azul);
  color: var(--folha);
  cursor: pointer;
}
button.secundario { background: transparent; color: var(--azul); }
button:focus-visible { outline: 2px solid var(--tinta); outline-offset: 2px; }
.conteudo { display: grid; gap: 22px; }
.resumo {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 1px;
  background: var(--regua);
  border: 1px solid var(--regua);
  border-radius: 10px;
  overflow: hidden;
}
.indicador { background: var(--folha); padding: 10px 12px; display: grid; gap: 2px; }
.indicador .nome {
  font-size: 0.72rem;
  color: var(--apagado);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.indicador .numero { font-size: 1.3rem; font-weight: 600; font-variant-numeric: tabular-nums; }
.bloco h2 { font-size: 1rem; margin: 0 0 8px; }
.legenda {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  font-size: 0.8rem;
  color: var(--apagado);
  margin-bottom: 8px;
}
.chave::before {
  content: "";
  display: inline-block;
  width: 10px;
  height: 10px;
  margin-right: 6px;
  border-radius: 2px;
  vertical-align: -1px;
}
.chave.pib::before { background: var(--azul); }
.chave.dinheiro::before { background: var(--ambar); }
.chave.equilibrio::before {
  width: 14px;
  height: 0;
  border-top: 2px dashed var(--tinta);
  border-radius: 0;
  vertical-align: 3px;
}
.grafico {
  position: relative;
  height: 180px;
  display: flex;
  align-items: flex-end;
  gap: 3px;
  border-bottom: 1px solid var(--tinta);
  background: repeating-linear-gradient(to top, transparent 0, transparent 35px, var(--regua) 35px, var(--regua) 36px);
}
.coluna { flex: 1; min-width: 0; height: 100%; display: flex; align-items: flex-end; gap: 1px; }
.barra { flex: 1; min-height: 1px; border-radius: 2px 2px 0 0; }
.barra.pib { background: var(--azul); }
.barra.dinheiro { background: var(--ambar); }
.linha-equilibrio {
  position: absolute;
  left: 0;
  right: 0;
  border-top: 2px dashed var(--tinta);
  opacity: 0.55;
  pointer-events: none;
}
.rolagem { overflow-x: auto; }
table.godley {
  width: 100%;
  min-width: 420px;
  border-collapse: collapse;
  background: var(--folha);
  font-size: 0.9rem;
}
.godley th, .godley td {
  padding: 8px 10px;
  text-align: right;
  border-bottom: 1px solid var(--regua);
}
.godley th[scope=row], .godley thead th:first-child { text-align: left; font-weight: 500; }
.godley thead th {
  font-size: 0.72rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--apagado);
  border-bottom: 2px solid var(--tinta);
}
.godley td.num {
  font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  font-variant-numeric: tabular-nums;
}
.godley td.negativo { color: var(--vermelho); }
.godley td.soma { color: var(--apagado); }
.godley tfoot th, .godley tfoot td {
  font-weight: 600;
  border-top: 2px solid var(--tinta);
  border-bottom: none;
}
.explica {
  margin: 0 0 8px;
  max-width: 65ch;
  font-size: 0.85rem;
  line-height: 1.5;
  color: var(--apagado);
}
.verificacao { margin: 8px 0 0; font-size: 0.85rem; font-weight: 600; }
.verificacao.ok { color: var(--azul); }
.verificacao.erro { color: var(--vermelho); }
.notas ol { margin: 0 0 10px; padding-left: 20px; line-height: 1.6; }
"""



-- PROGRAMA


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
