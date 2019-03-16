module Main exposing (main)

import Browser
import Browser.Navigation
import Checklist exposing (Checklist)
import Dict exposing (Dict)
import Html exposing (Html, div, h1, img, text)
import Html.Attributes as Attr exposing (src)
import Html.Events as Events
import Url exposing (Url)
import Url.Parser as U exposing ((</>))



---- MODEL ----


type alias Model =
    { checklists : Dict Checklist.Id Checklist
    , page : Page
    , key : Browser.Navigation.Key
    }


type alias Flags =
    {}


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { checklists = Dict.fromList [ ( 1, { id = 1, name = "Back from Work", items = [] } ) ]
      , page = HomePage
      , key = key
      }
    , Cmd.none
    )



---- ROUTING ----


type Page
    = HomePage
    | ChecklistPage Checklist.Id


type Route
    = HomeRoute
    | ChecklistRoute Checklist.Id


routes =
    U.oneOf
        [ U.map HomeRoute U.top
        , U.map ChecklistRoute (U.s "checklists" </> U.int)
        ]


route url model =
    case U.parse routes url of
        Nothing ->
            ( model, Cmd.none )

        Just HomeRoute ->
            ( { model | page = HomePage }, Cmd.none )

        Just (ChecklistRoute id) ->
            ( { model | page = ChecklistPage id }, Cmd.none )



---- UPDATE ----


type Msg
    = UrlChange Url.Url
    | UrlRequest Browser.UrlRequest
    | AddChecklist
    | AddItem Checklist.Id


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        UrlChange url ->
            route url model

        UrlRequest request ->
            case request of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Browser.Navigation.load url
                    )

        AddChecklist ->
            let
                newChecklist =
                    Checklist.empty (Dict.size model.checklists + 1)
            in
            ( { model | checklists = Dict.insert newChecklist.id newChecklist model.checklists }
            , Browser.Navigation.pushUrl model.key (Checklist.url newChecklist.id)
            )

        AddItem checklistId ->
            ( { model | checklists = Dict.update checklistId (Maybe.map Checklist.addItem) model.checklists }
            , Cmd.none
            )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        viewChecklist checklist =
            Html.li []
                [ Html.a [ Attr.href (Checklist.url checklist.id) ] [ text checklist.name ]
                ]

        checklists =
            Dict.values model.checklists
                |> List.map viewChecklist
    in
    case model.page of
        HomePage ->
            { title = "Checklists"
            , body =
                [ Html.main_ []
                    [ h1 [] [ text "Checklists" ]
                    , Html.ul [] checklists
                    , Html.button [ Events.onClick AddChecklist ] [ text "Add Checklist" ]
                    ]
                ]
            }

        ChecklistPage checklistId ->
            case Dict.get checklistId model.checklists of
                Just checklist ->
                    let
                        items =
                            List.map viewItem checklist.items

                        viewItem item =
                            Html.li [] [ text item.name ]
                    in
                    { title = checklist.name
                    , body =
                        [ Html.main_ []
                            [ h1 [] [ text checklist.name ]
                            , Html.ul [] items
                            , Html.button [ Events.onClick (AddItem checklist.id) ] [ text "Add Item" ]
                            ]
                        ]
                    }

                Nothing ->
                    { title = "404 - Page Not Found"
                    , body = [ text "404" ]
                    }



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , onUrlChange = UrlChange
        , onUrlRequest = UrlRequest
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
