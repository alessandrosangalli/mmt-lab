module Sfc.Matrix exposing
    ( Flow
    , Row
    , Sector(..)
    , columnTotal
    , isBalanced
    , rowTotal
    , rows
    )

{-| Transaction-flow matrix of a stock-flow consistent (SFC) model.

Every flow leaves one sector and enters another, so each row of the matrix
sums to zero by construction. What a model still has to get right is the
columns: each sector's inflows must equal its outflows, including the change
in the assets it holds. `isBalanced` checks exactly that.

-}


type Sector
    = Households
    | Firms
    | Banks
    | Government
    | CentralBank
    | RestOfWorld


{-| A payment of `amount` from one sector to another.
-}
type alias Flow =
    { label : String
    , from : Sector
    , to : Sector
    , amount : Float
    }


{-| One line of the matrix: a cell per sector, empty where the sector takes
no part in the flow.
-}
type alias Row =
    { label : String
    , cells : List (Maybe Float)
    }


rows : List Sector -> List Flow -> List Row
rows sectors flows =
    List.map (toRow sectors) flows


toRow : List Sector -> Flow -> Row
toRow sectors flow =
    { label = flow.label
    , cells = List.map (entry flow) sectors
    }


entry : Flow -> Sector -> Maybe Float
entry flow sector =
    if flow.from == flow.to then
        Nothing

    else if sector == flow.from then
        Just (negate flow.amount)

    else if sector == flow.to then
        Just flow.amount

    else
        Nothing


rowTotal : Row -> Float
rowTotal matrixRow =
    List.sum (List.filterMap identity matrixRow.cells)


columnTotal : Sector -> List Flow -> Float
columnTotal sector flows =
    List.sum (List.filterMap (\flow -> entry flow sector) flows)


{-| True when every flow stays inside the given sectors and every sector's
column sums to zero, up to floating-point rounding.
-}
isBalanced : List Sector -> List Flow -> Bool
isBalanced sectors flows =
    let
        scale =
            flows
                |> List.map (\flow -> abs flow.amount)
                |> List.maximum
                |> Maybe.withDefault 0
                |> max 1

        tolerance =
            scale * 1.0e-9

        isKnown flow =
            List.member flow.from sectors && List.member flow.to sectors

        columnCloses sector =
            abs (columnTotal sector flows) <= tolerance
    in
    List.all isKnown flows && List.all columnCloses sectors
