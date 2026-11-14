module Scenario exposing
    ( Change
    , Scenario
    , default
    , maxChanges
    , maxHorizon
    , minHorizon
    , policyAt
    , run
    , sanitize
    )

{-| A scenario is an experiment that can be repeated exactly: the policy the
economy starts with, the dated changes to it, and how many periods to run.
The whole simulation is a pure function of this value.
-}

import Model.Sim as Sim exposing (Period, Policy)


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
    { initial = { spending = 20, taxRatePct = 20 }
    , changes = []
    , horizon = 40
    }


{-| Bring every value into the range the model accepts. Order is kept.
-}
sanitize : Scenario -> Scenario
sanitize scenario =
    { initial = sanitizePolicy scenario.initial
    , changes =
        scenario.changes
            |> List.take maxChanges
            |> List.map sanitizeChange
    , horizon = clamp minHorizon maxHorizon scenario.horizon
    }


sanitizeChange : Change -> Change
sanitizeChange change =
    { period = clamp 2 maxHorizon change.period
    , policy = sanitizePolicy change.policy
    }


sanitizePolicy : Policy -> Policy
sanitizePolicy policy =
    { spending = clamp 0 50 policy.spending
    , taxRatePct = clamp 5 50 policy.taxRatePct
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


{-| Every period of the scenario, oldest first.
-}
run : Scenario -> List Period
run scenario =
    List.range 1 scenario.horizon
        |> List.foldl (\period history -> Sim.advance (policyAt scenario period) history) []
        |> List.reverse
