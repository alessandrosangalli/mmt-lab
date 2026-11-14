module Models exposing (Info, ModelId(..), all, fromVersion, info, run)

{-| The catalogue of models the laboratory can run.
-}

import Engine exposing (Snapshot)
import Model.Pc as Pc
import Model.Sim as Sim
import Policy exposing (Policy)
import Scenario exposing (Scenario)
import Sfc.Matrix exposing (Sector)


type ModelId
    = SimModel
    | PcModel


{-| What the screen needs to know about a model.

`version` names the model and its equations. It changes whenever the same
scenario would produce different numbers, so that an old link can be told
apart from a current one.

-}
type alias Info =
    { version : String
    , name : String
    , summary : String
    , wealthLabel : String
    , usesInterestRate : Bool
    , sectors : List Sector
    , steadyStateIncome : Policy -> Maybe Float
    , notes : List String
    }


all : List ModelId
all =
    [ SimModel, PcModel ]


info : ModelId -> Info
info id =
    case id of
        SimModel ->
            { version = "sim-1"
            , name = "SIM: só dinheiro"
            , summary = "O modelo mais simples de Godley e Lavoie (cap. 3). Famílias, empresas e governo, e um único ativo: o dinheiro que o governo emite quando gasta."
            , wealthLabel = "Dinheiro guardado pelas famílias"
            , usesInterestRate = False
            , sectors = Sim.sectors
            , steadyStateIncome = \policy -> Just (Sim.steadyStateIncome policy)
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
            , wealthLabel = "Riqueza das famílias (dinheiro e títulos)"
            , usesInterestRate = True
            , sectors = Pc.sectors
            , steadyStateIncome = Pc.steadyStateIncome
            , notes =
                [ "O juro é o que o banco central decidir: ele compra os títulos que as famílias não quiserem."
                , "O banco central devolve ao governo o juro que recebe, então só o juro pago às famílias pesa no déficit."
                , "Suba o juro e compare: neste modelo, o equilíbrio fica com PIB maior, porque o governo paga mais juros às famílias. Isso é consequência das premissas do modelo, não uma evidência sobre a economia real."
                , "Com imposto baixo e juro alto, o juro da dívida cresce mais rápido que a arrecadação e a economia deixa de ter um ponto de equilíbrio."
                , "Os parâmetros de carteira vêm do livro e só fazem sentido com juros baixos. Por isso o controle para em 6%."
                ]
            }


run : ModelId -> Scenario -> List Snapshot
run id scenario =
    case id of
        SimModel ->
            Engine.run Sim.model scenario

        PcModel ->
            Engine.run Pc.model scenario


{-| The model a version string refers to, even when the version is not the
current one.
-}
fromVersion : String -> Maybe ModelId
fromVersion version =
    if String.startsWith "sim-" version then
        Just SimModel

    else if String.startsWith "pc-" version then
        Just PcModel

    else
        Nothing
