port module Main exposing (init, main, update, view)

import Browser
import Html exposing (Attribute, Html, div, h1, img, input, label, li, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe
import Ports exposing (..)
import Types exposing (..)


createItem : String -> Cmd msg
createItem name =
    let
        encoded =
            encodeCreateAction name
    in
    updateItem encoded


toggleItem : Item -> Cmd msg
toggleItem item =
    let
        newItem =
            Item item.name (not item.isDone) item.id

        encoded =
            encodeAction newItem "update"
    in
    updateItem encoded


initialModel =
    { items = []
    , newItemName = Nothing
    }


init : Model -> ( Model, Cmd Msg )
init flags =
    ( flags, updateItem (Encode.string "app started") )


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
                    ( { model | newItemName = Nothing }, createItem name )

                Nothing ->
                    ( model, Cmd.none )

        ToggleItem item ->
            ( model, toggleItem item )

        GetItems encoded ->
            ( model, Cmd.none )

        SetItems items ->
            ( { model | items = items }, Cmd.none )


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
    div [ class "p-4 m-6 ml-auto mr-auto max-w-md bg-white shadow-lg rounded" ]
        [ ul [ class "list-reset" ] (List.map viewItem model.items)
        , viewAddItemInput newItem
        ]


viewAddItemInput : String -> Html Msg
viewAddItemInput newItemName =
    let
        inputClasses =
            "block w-full text-xl pt-2 pb-2 border-b"
    in
    input [ class inputClasses, type_ "text", placeholder "Lisää listalle...", value newItemName, onInput ChangeNewItem, onEnter CreateNewItem ] []


viewItem : Item -> Html Msg
viewItem item =
    let
        defaultClasses =
            "block text-xl cursor-pointer"

        labelClasses =
            if item.isDone then
                defaultClasses ++ " line-through opacity-50"

            else
                defaultClasses
    in
    li [ class "pb-2 pt-2 border-b border-grey-light hover:bg-grey-lighter" ]
        [ label [ class labelClasses, onClick (ToggleItem item) ]
            [ text item.name
            ]
        ]


main : Program Model Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
