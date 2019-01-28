port module Main exposing (init, main, update, view)

import Browser
import Html exposing (Attribute, Html, button, div, h1, img, input, label, li, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import List
import Maybe
import Ports exposing (..)
import Types exposing (..)


createItem : String -> String -> Cmd msg
createItem name listId =
    let
        encoded =
            encodeCreateItemAction name listId
    in
    updateDataStore encoded


createList : String -> Cmd msg
createList name =
    let
        encoded =
            encodeCreateListAction name
    in
    updateDataStore encoded


changeList : String -> Cmd msg
changeList listId =
    let
        encoded =
            encodeChangeListAction listId
    in
    updateDataStore encoded


toggleItem : Item -> String -> Cmd msg
toggleItem item listId =
    let
        newItem =
            Item item.name (not item.isDone) item.id

        encoded =
            encodeUpdateItemAction newItem listId
    in
    updateDataStore encoded


sortByIsDone a b =
    if a.isDone == b.isDone then
        EQ

    else if a.isDone && not b.isDone then
        GT

    else
        LT


initialModel =
    { items = []
    , newItemName = Nothing
    }


init : Model -> ( Model, Cmd Msg )
init flags =
    ( flags, updateDataStore (Encode.string "app started") )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CreateNewList ->
            case model.newListName of
                Just name ->
                    ( { model | newListName = Nothing }, createList name )

                Nothing ->
                    ( model, Cmd.none )

        ChangeNewList newName ->
            ( { model | newListName = Just newName }, Cmd.none )

        ToggleLists ->
            ( { model | isListsOpen = not model.isListsOpen }, Cmd.none )

        SelectList shoppingList ->
            ( { model | currentlySelectedListId = Just shoppingList.id, isListsOpen = not model.isListsOpen }, changeList shoppingList.id )

        ChangeNewItem newName ->
            ( { model | newItemName = Just newName }, Cmd.none )

        CreateNewItem ->
            case model.newItemName of
                Just name ->
                    case model.currentlySelectedListId of
                        Just listId ->
                            ( { model | newItemName = Nothing }, createItem name listId )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ToggleItem item ->
            case model.currentlySelectedListId of
                Just listId ->
                    ( { model | newItemName = Nothing }, toggleItem item listId )

                Nothing ->
                    ( model, Cmd.none )

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

        newList =
            Maybe.withDefault "" model.newListName

        currentListId =
            Maybe.withDefault "<nothing>" model.currentlySelectedListId
    in
    div []
        [ viewHeader model.isListsOpen
        , viewItems model.isListsOpen (getCurrentList model.lists model.currentlySelectedListId) model.items newItem
        , viewListsMenu model.isListsOpen model.lists currentListId newList
        ]


getCurrentList : List ShoppingList -> Maybe String -> Maybe ShoppingList
getCurrentList lists id =
    case id of
        Just listId ->
            List.head (List.filter (\l -> l.id == listId) lists)

        Nothing ->
            Nothing


viewHeader : Bool -> Html Msg
viewHeader isListsOpen =
    let
        buttonLabel =
            if isListsOpen then
                "Ostoslista"

            else
                "Listat"
    in
    div [ class "flex justify-between items-center bg-grey-lighter shadow-lg" ]
        [ div [ class "p-4 font-bold uppercase tracking-wide text-grey-darker text-sm" ]
            [ text "😼 Kauppakatti"
            ]
        , div [ class "p-4 text-grey-darker" ]
            [ button [ class "p-2 rounded border border-grey text-grey-darker text-sm uppercase tracking-wide font-bold", onClick ToggleLists ] [ text buttonLabel ]
            ]
        ]


viewAddItemInput : String -> Html Msg
viewAddItemInput newItemName =
    let
        inputClasses =
            "block w-full text-xl pt-2 pb-2 border-b"
    in
    input [ class inputClasses, type_ "text", placeholder "Lisää listalle...", value newItemName, onInput ChangeNewItem, onEnter CreateNewItem ] []


viewAddListInput : String -> Html Msg
viewAddListInput newListName =
    let
        inputClasses =
            "block w-full text-xl pt-2 pb-2 border-b"
    in
    input [ class inputClasses, type_ "text", placeholder "Luo uusi lista...", value newListName, onInput ChangeNewList, onEnter CreateNewList ] []


viewItems : Bool -> Maybe ShoppingList -> List Item -> String -> Html Msg
viewItems isListsOpen shoppingList items newItem =
    if isListsOpen then
        div [] []

    else
        case shoppingList of
            Just list ->
                div [ class "p-4 mt-3 ml-3 mr-3 md:ml-auto md:mr-auto md:max-w-md bg-white shadow-lg rounded" ]
                    [ h1 [ class "mb-4 font-bold uppercase tracking-wide text-grey-darker text-sm" ] [ text list.name ]
                    , ul [ class "list-reset" ] (List.map viewItem (List.sortWith sortByIsDone items))
                    , viewAddItemInput newItem
                    ]

            Nothing ->
                div [] []


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
    li [ class "pb-2 pt-2 border-b border-grey-light hover:bg-grey-lighter cursor-pointer", onClick (ToggleItem item) ]
        [ label [ class labelClasses ]
            [ text item.name
            ]
        ]


viewListsMenu : Bool -> List ShoppingList -> String -> String -> Html Msg
viewListsMenu isListsOpen lists currentListId newList =
    if not isListsOpen then
        div [] []

    else
        div [ class "p-4 mt-3 ml-3 mr-3 md:ml-auto md:mr-auto md:max-w-md bg-white shadow-lg rounded" ]
            [ h1 [ class "mb-4 font-bold uppercase tracking-wide text-grey-darker text-sm" ] [ text "Listat" ]
            , ul [ class "list-reset" ] (List.map (viewList currentListId) (List.sortBy .name lists))
            , viewAddListInput newList
            ]


viewList : String -> ShoppingList -> Html Msg
viewList selectedListId list =
    let
        defaultClasses =
            "block text-xl cursor-pointer"

        labelClasses =
            if selectedListId == list.id then
                defaultClasses ++ " font-bold"

            else
                defaultClasses
    in
    li [ class "pb-2 pt-2 border-b border-grey-light hover:bg-grey-lighter cursor-pointer", onClick (SelectList list) ]
        [ label [ class labelClasses ]
            [ text list.name
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
