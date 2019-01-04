port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Attribute, Html, div, h1, img, input, li, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe


port outputValue : Encode.Value -> Cmd msg


port inputValue : (Int -> msg) -> Sub msg


encodeAction : Item -> String -> Encode.Value
encodeAction item action =
    Encode.object
        [ ( "action", Encode.string action )
        , ( "name", Encode.string item.name )
        , ( "isDone", Encode.bool item.isDone )
        ]


createItem : String -> Cmd msg
createItem name =
    let
        item =
            Item name False

        encodedItem =
            encodeAction item "create"
    in
    outputValue encodedItem


type alias Item =
    { name : String
    , isDone : Bool
    }


type alias OutboundMsg =
    { action : OutboundMsgType
    , item : Item
    }


type alias Model =
    { items : List Item
    , newItemName : Maybe String
    }


initialModel =
    { items = []
    , newItemName = Nothing
    }


init : Model -> ( Model, Cmd Msg )
init flags =
    ( flags, outputValue (Encode.string "app started") )


type OutboundMsgType
    = Create
    | Update


type Msg
    = NoOp
    | ChangeNewItem String
    | CreateNewItem


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ChangeNewItem newName ->
            ( { model | newItemName = Just newName }, Cmd.none )

        CreateNewItem ->
            case model.newItemName of
                Just name ->
                    ( model, createItem name )

                Nothing ->
                    ( model, Cmd.none )


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed msg

            else
                Decode.fail "not ENTER"
    in
    on "keydown" (Decode.andThen isEnter keyCode)


view : Model -> Html Msg
view model =
    let
        newItem =
            Maybe.withDefault "" model.newItemName
    in
    div []
        [ h1 [] [ text "Kauppakatti" ]
        , ul [] (List.map viewItem model.items)
        , input [ placeholder "Lisää listalle...", value newItem, onInput ChangeNewItem, onEnter CreateNewItem ] []
        ]


viewItem : Item -> Html Msg
viewItem item =
    li [] [ text item.name ]


main : Program Model Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
