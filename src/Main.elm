port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Attribute, Html, div, h1, img, input, label, li, text, ul)
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
        , ( "id", Encode.string item.id )
        ]


encodeCreateAction : String -> Encode.Value
encodeCreateAction name =
    Encode.object
        [ ( "action", Encode.string "create" )
        , ( "name", Encode.string name )
        ]


createItem : String -> Cmd msg
createItem name =
    let
        encoded =
            encodeCreateAction name
    in
    outputValue encoded


toggleItem : Item -> Cmd msg
toggleItem item =
    let
        newItem =
            Item item.name (not item.isDone) item.id

        encoded =
            encodeAction newItem "update"
    in
    outputValue encoded


type alias Item =
    { name : String
    , isDone : Bool
    , id : String
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
    | ToggleItem Item


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

        ToggleItem item ->
            ( model, toggleItem item )


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
    li []
        [ label []
            [ input [ type_ "checkbox", checked item.isDone, onClick (ToggleItem item) ] []
            , text (item.name ++ " (" ++ item.id ++ ")")
            ]
        ]


main : Program Model Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
