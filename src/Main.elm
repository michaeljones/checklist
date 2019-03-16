module Main exposing (CheckItem, Checklist, Model, Msg(..), init, main, update, view)

import Browser
import Browser.Navigation
import Html exposing (Html, div, h1, img, text)
import Html.Attributes as Attr exposing (src)
import Url exposing (Url)
import Url.Parser as U exposing ((</>))



---- MODEL ----


type alias Model =
    { checklists : List Checklist
    , page : Page
    , key : Browser.Navigation.Key
    }


type alias Checklist =
    { id : ChecklistId
    , name : String
    , items : List CheckItem
    }


type alias ChecklistId =
    Int


type alias CheckItem =
    { name : String
    , checked : Bool
    }


type alias Flags =
    {}


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { checklists = [ { id = 1, name = "Back from Work", items = [] } ]
      , page = HomePage
      , key = key
      }
    , Cmd.none
    )



---- ROUTING ----


type Page
    = HomePage
    | ChecklistPage ChecklistId


type Route
    = HomeRoute
    | ChecklistRoute ChecklistId


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



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        viewChecklist checklist =
            Html.a [ Attr.href ("/checklists/" ++ String.fromInt checklist.id) ] [ text checklist.name ]

        checklists =
            List.map viewChecklist model.checklists
    in
    case model.page of
        HomePage ->
            { title = "Checklists"
            , body =
                [ Html.main_ []
                    [ h1 [] [ text "Checklists" ]
                    , Html.section [] checklists
                    ]
                ]
            }

        ChecklistPage checklistId ->
            let
                maybe =
                    List.filter (\c -> c.id == checklistId) model.checklists
                        |> List.head
            in
            case maybe of
                Just checklist ->
                    { title = checklist.name
                    , body =
                        [ Html.main_ []
                            [ h1 [] [ text checklist.name ]
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
