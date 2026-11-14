module Models exposing (Info, ModelId(..), SteadyState(..), all, defaultScenario, fromVersion, info, run)

{-| The catalogue of models the laboratory can run.
-}

import Engine exposing (Run)
import Model.Brazil as Brazil
import Model.Open as Open
import Model.Pc as Pc
import Model.Sim as Sim
import Policy exposing (Policy)
import Premise exposing (Premise)
import Scenario exposing (Scenario)
import Sfc.Matrix exposing (Sector)


type ModelId
    = SimModel
    | PcModel
    | OpenModel
    | BrazilModel


{-| Where income settles under a constant policy: a known value, nowhere at
all, or a value this model has no formula for.
-}
type SteadyState
    = SettlesAt Float
    | NeverSettles
    | NotComputed


{-| What the screen needs to know about a model.

`version` names the model and its equations. It changes whenever the same
scenario would produce different numbers, so that an old link can be told
apart from a current one.

-}
type alias Info =
    { version : String
    , name : String
    , summary : String
    , incomeLabel : String
    , wealthLabel : String
    , usesInterestRate : Bool
    , hasForeignSector : Bool
    , sectors : List Sector
    , defaultPolicy : Policy
    , steadyStateIncome : Policy -> SteadyState
    , premises : List Premise
    , notes : List String
    }


all : List ModelId
all =
    [ SimModel, PcModel, OpenModel, BrazilModel ]


info : ModelId -> Info
info id =
    case id of
        SimModel ->
            { version = "sim-1"
            , name = "SIM: só dinheiro"
            , summary = "O modelo mais simples de Godley e Lavoie (cap. 3). Famílias, empresas e governo, e um único ativo: o dinheiro que o governo emite quando gasta."
            , incomeLabel = "PIB em cada período"
            , wealthLabel = "Dinheiro guardado pelas famílias"
            , usesInterestRate = False
            , hasForeignSector = False
            , sectors = Sim.sectors
            , defaultPolicy = Policy.default
            , steadyStateIncome = \policy -> SettlesAt (Sim.steadyStateIncome policy)
            , premises = []
            , notes =
                [ "No começo ninguém tem dinheiro. O governo gasta primeiro e só depois recolhe impostos."
                , "Todo déficit vira dinheiro guardado pelas famílias, centavo por centavo."
                , "O PIB caminha até G ÷ θ. Nesse ponto o déficit zera sozinho, sem ninguém decidir cortar nada."
                , "Adicione uma mudança de política e veja a economia buscar um novo equilíbrio a partir daquele período."
                ]
            }

        PcModel ->
            { version = "pc-1"
            , name = "PC: títulos e juros"
            , summary = "O modelo PC de Godley e Lavoie (cap. 4). Acrescenta títulos públicos, um banco central e a taxa de juros. As famílias dividem a riqueza entre dinheiro e títulos, e o banco central compra os títulos que sobram."
            , incomeLabel = "PIB em cada período"
            , wealthLabel = "Riqueza das famílias (dinheiro e títulos)"
            , usesInterestRate = True
            , hasForeignSector = False
            , sectors = Pc.sectors
            , defaultPolicy = Policy.default
            , steadyStateIncome =
                \policy ->
                    case Pc.steadyStateIncome policy of
                        Just income ->
                            SettlesAt income

                        Nothing ->
                            NeverSettles
            , premises = []
            , notes =
                [ "O juro é o que o banco central decidir: ele compra os títulos que as famílias não quiserem."
                , "O banco central devolve ao governo o juro que recebe, então só o juro pago às famílias pesa no déficit."
                , "Suba o juro e compare: neste modelo, o equilíbrio fica com PIB maior, porque o governo paga mais juros às famílias. Isso é consequência das premissas do modelo, não uma evidência sobre a economia real."
                , "Com imposto baixo e juro alto, o juro da dívida cresce mais rápido que a arrecadação e a economia deixa de ter um ponto de equilíbrio."
                , "Os parâmetros de carteira vêm do livro e só fazem sentido com juros baixos. Por isso o controle para em 6%."
                ]
            }

        OpenModel ->
            { version = "open-1"
            , name = "OPEN: economia aberta"
            , summary = "O modelo OPENFLEX de Godley e Lavoie (cap. 12). Dois países trocam mercadorias e compram títulos um do outro, com câmbio flutuante. Você controla a política do país doméstico; o outro país não muda. A economia começa parada, no estado estacionário do livro: gasto 16, alíquota de 20% e juro de 3%. Os parâmetros são os do livro, para dois países iguais, e não representam o Brasil."
            , incomeLabel = "PIB real em cada período"
            , wealthLabel = "Riqueza das famílias (dinheiro e títulos)"
            , usesInterestRate = True
            , hasForeignSector = True
            , sectors = Open.sectors
            , defaultPolicy = Open.defaultPolicy
            , steadyStateIncome = \_ -> NotComputed
            , premises = Open.premises
            , notes =
                [ "Aumente o gasto público: a renda sobe, as importações crescem, a conta corrente fica negativa e a moeda perde valor, até a conta corrente voltar a zero."
                , "A moeda mais fraca encarece os importados, e o nível de preços doméstico sobe. É o repasse do câmbio aos preços."
                , "Os três saldos setoriais (setor privado, governo e exterior) somam zero em todo período."
                , "O modelo é muito sensível ao juro. Com os parâmetros do livro, um ponto a mais de juro valoriza a moeda em cerca de 30% de imediato, e acima de 4% o modelo deixa de ter solução depois de alguns períodos."
                , "Em Premissas do modelo, use as estimativas brasileiras para o comércio e aumente um pouco o gasto: a moeda continua caindo e a conta corrente não fecha. Com os valores do livro, ela fecha. Use Comparar com outro cenário para ver os dois lado a lado."
                , "A diferença vem de uma condição clássica: o câmbio só corrige as contas externas quando exportações e importações, somadas, reagem bastante ao preço. O mapa de premissas mostra essa fronteira."
                , "Os demais parâmetros continuam sendo os do livro. A calibração para o Brasil ainda não foi feita, então isso mostra o que cada premissa faz, não o que aconteceria no Brasil."
                ]
            }

        BrazilModel ->
            { version = "brazil-2"
            , name = "BRASIL: ponto de partida brasileiro"
            , summary = "O modelo OPENFLEX do livro, com dois acréscimos: transferências do governo às famílias e crescimento. Cada período é um trimestre, e tudo é mostrado em relação à tendência: uma linha reta significa crescer no ritmo normal, com o PIB real subindo 2,3% ao ano e os preços 4,5%. Na partida, a receita do governo é 41,9% do PIB, o consumo do governo 18,8%, os juros 11,3%, as transferências 17,9% e o déficit 5,4%; a dívida pública é 82% do PIB anual, com 9,9% dela no exterior. A política inicial é gasto 18, alíquota de 38% e juro de 3,5% por trimestre, cerca de 14,75% ao ano. É uma calibração parcial, não uma previsão."
            , incomeLabel = "PIB real em relação à tendência, por trimestre"
            , wealthLabel = "Riqueza das famílias em relação à tendência"
            , usesInterestRate = True
            , hasForeignSector = True
            , sectors = Brazil.sectors
            , defaultPolicy = Brazil.defaultPolicy
            , steadyStateIncome = \_ -> NotComputed
            , premises = Brazil.premises
            , notes =
                [ "Sem mudança de política, nada se move: a economia segue na tendência, quaisquer que sejam as premissas. O déficit de 5,4% do PIB não é desequilíbrio. É o que mantém a dívida constante como proporção de um PIB que cresce."
                , "Aumente o gasto de 18 para 19. O PIB fica acima da tendência e a moeda perde valor aos poucos, até se acomodar cerca de 25% abaixo. A dívida sobe de 3,28 para perto de 3,35 vezes o PIB trimestral e para."
                , "Leve as duas respostas de comércio a 0,70, o valor do livro, e repita: a moeda se acomoda só 5% abaixo, e muito mais rápido."
                , "Suba o juro meio ponto por trimestre, que são dois pontos ao ano: a moeda se valoriza cerca de 6% de imediato, dentro da faixa medida no Brasil. Depois se desvaloriza, e a dívida sobe em proporção ao PIB."
                , "As transferências, 17,9% do PIB, são um valor fixo do modelo, e não um controle. Elas saem da conta: é o que sobra depois de fixados a receita, o gasto, a dívida e o juro."
                , "Na partida, a conta corrente é positiva. O Brasil tem déficit. O modelo dá às famílias um quinto da riqueza em títulos estrangeiros, proporção herdada do livro e ainda sem fonte brasileira."
                , "O modelo não tem investimento, o outro país tem o tamanho do Brasil, e o consumo a partir da riqueza não vem de estimativa. O arquivo CALIBRATION.md, no repositório, diz de onde vem cada número e o que falta."
                , "Nada aqui é resultado sobre o Brasil. Os critérios das teses ainda não foram pré-registrados."
                ]
            }


run : ModelId -> Scenario -> Run
run id scenario =
    case id of
        SimModel ->
            Engine.run Sim.model scenario

        PcModel ->
            Engine.run Pc.model scenario

        OpenModel ->
            Engine.run Open.model scenario

        BrazilModel ->
            Engine.run Brazil.model scenario


{-| The scenario a model starts with.
-}
defaultScenario : ModelId -> Scenario
defaultScenario id =
    let
        base =
            Scenario.default
    in
    { base | initial = (info id).defaultPolicy }


{-| The model a version string refers to, even when the version is not the
current one.
-}
fromVersion : String -> Maybe ModelId
fromVersion version =
    if String.startsWith "sim-" version then
        Just SimModel

    else if String.startsWith "pc-" version then
        Just PcModel

    else if String.startsWith "open-" version then
        Just OpenModel

    else if String.startsWith "brazil-" version then
        Just BrazilModel

    else
        Nothing
