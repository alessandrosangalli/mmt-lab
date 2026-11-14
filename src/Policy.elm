module Policy exposing (Policy, default, sanitize)

{-| What the government and the central bank decide in a period. Every model
receives the same policy; a model without bills ignores the interest rate.
-}


type alias Policy =
    { spending : Float
    , taxRatePct : Float
    , interestRatePct : Float
    }


default : Policy
default =
    { spending = 20
    , taxRatePct = 20
    , interestRatePct = 2.5
    }


{-| Bring every value into the range the models accept.

The interest rate stops at 6% because the portfolio parameters of model PC
come from the book and stop making sense a little above that.

-}
sanitize : Policy -> Policy
sanitize policy =
    { spending = clamp 0 50 policy.spending
    , taxRatePct = clamp 5 50 policy.taxRatePct
    , interestRatePct = clamp 0 6 policy.interestRatePct
    }
