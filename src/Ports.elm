port module Ports exposing (decodeUpdatedItemsPayload, encodeAction, encodeChangeListAction, encodeCreateItemAction, encodeCreateListAction, encodeUpdateItemAction, itemDecoder, itemsUpdated, mapItemsUpdated, subscriptions, updateDataStore)

import Json.Decode as Decode
import Json.Encode as Encode
import Types exposing (..)


port updateDataStore : Encode.Value -> Cmd msg


port itemsUpdated : (Decode.Value -> msg) -> Sub msg


encodeAction : Item -> String -> Encode.Value
encodeAction item action =
    Encode.object
        [ ( "action", Encode.string action )
        , ( "name", Encode.string item.name )
        , ( "isDone", Encode.bool item.isDone )
        , ( "id", Encode.string item.id )
        ]


encodeUpdateItemAction : Item -> String -> Encode.Value
encodeUpdateItemAction item listId =
    Encode.object
        [ ( "action", Encode.string "update" )
        , ( "name", Encode.string item.name )
        , ( "isDone", Encode.bool item.isDone )
        , ( "id", Encode.string item.id )
        , ( "listId", Encode.string listId )
        ]


encodeCreateItemAction : String -> String -> Encode.Value
encodeCreateItemAction name listId =
    Encode.object
        [ ( "action", Encode.string "create" )
        , ( "name", Encode.string name )
        , ( "listId", Encode.string listId )
        ]


encodeCreateListAction : String -> Encode.Value
encodeCreateListAction name =
    Encode.object
        [ ( "action", Encode.string "new-list" )
        , ( "name", Encode.string name )
        ]


encodeChangeListAction : String -> Encode.Value
encodeChangeListAction listId =
    Encode.object
        [ ( "action", Encode.string "change-list" )
        , ( "listId", Encode.string listId )
        ]


itemDecoder =
    Decode.map3 (\id name isDone -> { id = id, name = name, isDone = isDone }) (Decode.field "id" Decode.string) (Decode.field "name" Decode.string) (Decode.field "isDone" Decode.bool)


decodeUpdatedItemsPayload : Decode.Value -> Result Decode.Error (List Item)
decodeUpdatedItemsPayload json =
    Decode.decodeValue (Decode.list itemDecoder) json


mapItemsUpdated : Decode.Value -> Msg
mapItemsUpdated json =
    case decodeUpdatedItemsPayload json of
        Ok items ->
            SetItems items

        Err errorMessage ->
            let
                _ =
                    Debug.log "Error in mapItemsUpdated:" errorMessage
            in
            NoOp

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ itemsUpdated mapItemsUpdated
        ]
