port module Main exposing (main)

import Browser
import Browser.Navigation
import Checklist exposing (Checklist)
import Css
import Dict exposing (Dict)
import Html.Styled as Html exposing (Html, div, h1, img, text)
import Html.Styled.Attributes as Attr exposing (src)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Url exposing (Url)
import Url.Parser as U exposing ((</>))



---- MODEL ----


type alias Model =
    { checklists : Dict Checklist.Id Checklist
    , name : String
    , page : Page
    , key : Browser.Navigation.Key
    }


type alias Flags =
    { checklists : Decode.Value
    }


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        checklists =
            Decode.decodeValue (Decode.list Checklist.decoder) flags.checklists
                |> Result.mapError (Debug.log "Decode Error")
                |> Result.map (List.map (\checklist -> ( checklist.id, checklist )) >> Dict.fromList)
                |> Result.withDefault Dict.empty
    in
    ( { checklists = checklists
      , name = ""
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
            ( { model | page = HomePage, name = "" }, Cmd.none )

        Just (ChecklistRoute id) ->
            ( { model | page = ChecklistPage id, name = "" }, Cmd.none )



---- UPDATE ----


type Msg
    = UrlChange Url.Url
    | UrlRequest Browser.UrlRequest
    | AddChecklist
    | AddItem Checklist.Id
    | SetName String


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
            if String.isEmpty model.name then
                ( model, Cmd.none )

            else
                let
                    newChecklist =
                        Checklist.new (Dict.size model.checklists + 1) model.name

                    checklists =
                        Dict.insert newChecklist.id newChecklist model.checklists
                in
                ( { model
                    | checklists = checklists
                    , name = ""
                  }
                , Cmd.batch
                    [ Browser.Navigation.pushUrl model.key (Checklist.url newChecklist.id)
                    , save checklists
                    ]
                )

        AddItem checklistId ->
            if String.isEmpty model.name then
                ( model, Cmd.none )

            else
                let
                    checklists =
                        Dict.update checklistId (Maybe.map (Checklist.addItem model.name)) model.checklists
                in
                ( { model
                    | checklists = checklists
                    , name = ""
                  }
                , save checklists
                )

        SetName string ->
            ( { model | name = string }
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

        toUnstyled { title, body } =
            { title = title
            , body = [ Html.toUnstyled (div [] body) ]
            }

        mainStyle =
            Css.batch
                [ Css.displayFlex
                , Css.flexDirection Css.column
                , Css.margin (Css.px 20)
                ]

        buttonStyle =
            Css.batch
                [ Css.marginTop (Css.px 10)
                , Css.border Css.zero
                , Css.padding (Css.px 5)
                , Css.backgroundColor (Css.hex "#cccccc")
                ]
    in
    toUnstyled <|
        case model.page of
            HomePage ->
                { title = "Checklists"
                , body =
                    [ Html.main_ [ Attr.css [ mainStyle ] ]
                        [ h1 [] [ text "Checklists" ]
                        , Html.ul [] checklists
                        , Html.input [ Attr.type_ "text", Events.onInput SetName, Attr.value model.name ] []
                        , Html.button
                            [ Events.onClick AddChecklist
                            , Attr.css [ buttonStyle ]
                            ]
                            [ text "Add Checklist" ]
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
                            [ Html.main_ [ Attr.css [ mainStyle ] ]
                                [ h1 [] [ text checklist.name ]
                                , Html.ul [] items
                                , Html.input [ Attr.type_ "text", Events.onInput SetName, Attr.value model.name ] []
                                , Html.button
                                    [ Events.onClick (AddItem checklist.id)
                                    , Attr.css [ buttonStyle ]
                                    ]
                                    [ text "Add Item" ]
                                ]
                            ]
                        }

                    Nothing ->
                        { title = "404 - Page Not Found"
                        , body = [ text "404" ]
                        }



---- PORTS ----


port outPort : Encode.Value -> Cmd msg


save : Dict Checklist.Id Checklist -> Cmd msg
save checklists =
    let
        encoded =
            Dict.values checklists
                |> Encode.list Checklist.encode

        portMsg =
            Encode.object
                [ ( "type", Encode.string "save" )
                , ( "data", encoded )
                ]
    in
    outPort portMsg



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
