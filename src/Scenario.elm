module Scenario exposing
    ( Change
    , Scenario
    , addChange
    , default
    , maxChanges
    , maxHorizon
    , minHorizon
    , policyAt
    , removeChange
    , sanitize
    , updateChange
    )

{-| A scenario is an experiment that can be repeated exactly: the policy the
economy starts with, the dated changes to it, and how many periods to run.
Together with a model, it determines the whole simulation.
-}

import Dict
import Policy exposing (Policy)
import Premise exposing (Premises)


{-| From `period` on, the policy becomes `policy`.
-}
type alias Change =
    { period : Int
    , policy : Policy
    }


type alias Scenario =
    { initial : Policy
    , changes : List Change
    , horizon : Int
    , premises : Premises
    }


minHorizon : Int
minHorizon =
    5


maxHorizon : Int
maxHorizon =
    120


maxChanges : Int
maxChanges =
    6


default : Scenario
default =
    { initial = Policy.default
    , changes = []
    , horizon = 40
    , premises = Dict.empty
    }


{-| Bring every value into the range the models accept. Order is kept.
Premises are left alone: only a model knows the range of its own.
-}
sanitize : Scenario -> Scenario
sanitize scenario =
    { initial = Policy.sanitize scenario.initial
    , changes =
        scenario.changes
            |> List.take maxChanges
            |> List.map sanitizeChange
    , horizon = clamp minHorizon maxHorizon scenario.horizon
    , premises = scenario.premises
    }


sanitizeChange : Change -> Change
sanitizeChange change =
    { period = clamp 2 maxHorizon change.period
    , policy = Policy.sanitize change.policy
    }


{-| The policy in force in a given period: the most recent change that has
already happened, or the initial policy. When two changes share a period, the
one listed later wins.
-}
policyAt : Scenario -> Int -> Policy
policyAt scenario period =
    let
        pick change ( bestPeriod, bestPolicy ) =
            if change.period <= period && change.period >= bestPeriod then
                ( change.period, change.policy )

            else
                ( bestPeriod, bestPolicy )
    in
    List.foldl pick ( 0, scenario.initial ) scenario.changes
        |> Tuple.second



-- EDITING


{-| Append a change ten periods after the latest one, raising spending a
little so that it is visible at once. Does nothing once the list is full.
-}
addChange : Scenario -> Scenario
addChange scenario =
    if List.length scenario.changes >= maxChanges then
        scenario

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
                policyAt scenario period

            added =
                { period = period
                , policy = { current | spending = min 50 (current.spending + 5) }
                }
        in
        { scenario | changes = scenario.changes ++ [ added ] }


updateChange : Int -> (Change -> Change) -> Scenario -> Scenario
updateChange index edit scenario =
    let
        apply position change =
            if position == index then
                edit change

            else
                change
    in
    { scenario | changes = List.indexedMap apply scenario.changes }


removeChange : Int -> Scenario -> Scenario
removeChange index scenario =
    { scenario | changes = List.take index scenario.changes ++ List.drop (index + 1) scenario.changes }
