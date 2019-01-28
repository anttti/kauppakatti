module Types exposing (Item, Model, Msg(..), ShoppingList)

import Json.Encode as Encode


type alias Item =
    { name : String
    , isDone : Bool
    , id : String
    }


type alias ShoppingList =
    { name : String
    , id : String
    }


type alias Model =
    { items : List Item
    , lists : List ShoppingList
    , isListsOpen : Bool
    , currentlySelectedListId : Maybe String
    , newItemName : Maybe String
    , newListName : Maybe String
    }


type Msg
    = NoOp
    | CreateNewList
    | ChangeNewList String
    | ToggleLists
    | SelectList ShoppingList
    | CreateNewItem
    | ChangeNewItem String
    | ToggleItem Item
    | GetItems Encode.Value
    | SetItems (List Item)
