module Types exposing (Item, Model, Msg(..))

import Json.Encode as Encode


type alias Item =
    { name : String
    , isDone : Bool
    , id : String
    }


type alias Model =
    { items : List Item
    , newItemName : Maybe String
    }


type Msg
    = NoOp
    | ChangeNewItem String
    | CreateNewItem
    | ToggleItem Item
    | GetItems Encode.Value
    | SetItems (List Item)
