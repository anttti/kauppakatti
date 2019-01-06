port module Ports exposing (decodeUpdatedItemsPayload, encodeAction, encodeCreateAction, itemDecoder, itemsUpdated, mapItemsUpdated, subscriptions, updateItem)

import Json.Decode as Decode
import Json.Encode as Encode
import Types exposing (..)


port updateItem : Encode.Value -> Cmd msg


port itemsUpdated : (Decode.Value -> msg) -> Sub msg


encodeAction : Item -> String -> Encode.Value
encodeAction item action =
    Encode.object
        [ ( "action", Encode.string action )
        , ( "name", Encode.string item.name )
        , ( "isDone", Encode.bool item.isDone )
        , ( "id", Encode.string item.id )
        ]


encodeCreateAction : String -> Encode.Value
encodeCreateAction name =
    Encode.object
        [ ( "action", Encode.string "create" )
        , ( "name", Encode.string name )
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
    itemsUpdated mapItemsUpdated
