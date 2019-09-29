port module Main exposing (main)

import Array
import Browser
import Browser.Navigation
import Checklist exposing (Checklist)
import Css
import DateFormat as DF
import Dict exposing (Dict)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import File exposing (File)
import File.Download
import File.Select
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (src)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import Time exposing (Posix)
import Url exposing (Url)
import Url.Parser as U exposing ((</>))



---- MODEL ----


type alias ModelResult =
    Result String Model


extract : Result String ( Model, Cmd Msg ) -> ( ModelResult, Cmd Msg )
extract result =
    case result of
        Ok ( model, cmd ) ->
            ( Ok model, cmd )

        Err err ->
            ( Err err, Cmd.none )


type alias Model =
    { checklists : Dict Checklist.Id Checklist
    , name : String
    , page : Page
    , time : Posix
    , key : Browser.Navigation.Key
    }


encodeData : Model -> Encode.Value
encodeData model =
    let
        encodedChecklists =
            Dict.values model.checklists
                |> Encode.list Checklist.encode
    in
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "checklists", encodedChecklists )
        ]


type alias Flags =
    { data : Decode.Value
    , time : Float
    }


initResult : Flags -> Url -> Browser.Navigation.Key -> ( ModelResult, Cmd Msg )
initResult flags url key =
    let
        time =
            Time.millisToPosix (round flags.time)

        checklists =
            Decode.decodeValue (Decode.field "checklists" (Decode.list Checklist.decoder)) flags.data
                |> Result.map (List.map (Checklist.refresh time))
                |> Result.map (List.map (\checklist -> ( checklist.id, checklist )) >> Dict.fromList)

        modelResult =
            Ok Model
                |> applyResult checklists
                |> apply ""
                |> apply HomePage
                |> apply time
                |> apply key
                |> Result.map (route url)
                |> Result.mapError Decode.errorToString
    in
    extract modelResult


applyResult result resultFn =
    Result.map2 (\value fn -> fn value) result resultFn


apply value resultFn =
    Result.map (\fn -> fn value) resultFn



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
    let
        parsedRoute =
            { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
                |> U.parse routes
    in
    case parsedRoute of
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
    | Tick Posix
    | AddChecklist
    | AddItem Checklist.Id
    | SetName String
    | CheckItem Checklist.Id Int Bool
    | Download
    | Load
    | BackupLoaded File
    | BackupDataLoaded (Result Decode.Error (List Checklist))


updateResult : Msg -> ModelResult -> ( ModelResult, Cmd Msg )
updateResult msg model =
    Result.map (update msg) model
        |> extract


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        Tick time ->
            ( { model | time = time }
            , Cmd.none
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

                    newModel =
                        { model
                            | checklists = checklists
                            , name = ""
                        }
                in
                ( newModel
                , Cmd.batch
                    [ Browser.Navigation.pushUrl model.key (Checklist.url newChecklist.id)
                    , save newModel
                    ]
                )

        AddItem checklistId ->
            if String.isEmpty model.name then
                ( model, Cmd.none )

            else
                let
                    checklists =
                        Dict.update checklistId (Maybe.map (Checklist.addItem model.name)) model.checklists

                    newModel =
                        { model
                            | checklists = checklists
                            , name = ""
                        }
                in
                ( newModel
                , save newModel
                )

        SetName string ->
            ( { model | name = string }
            , Cmd.none
            )

        CheckItem checklistId itemIndex checked ->
            let
                checklists =
                    Dict.update checklistId (Maybe.map (Checklist.setItem itemIndex checkedTime)) model.checklists

                checkedTime =
                    if checked then
                        Just model.time

                    else
                        Nothing

                newModel =
                    { model | checklists = checklists }
            in
            ( newModel
            , save newModel
            )

        Download ->
            let
                data =
                    encodeData model

                jsonString =
                    Encode.encode 4 data

                datePart =
                    DF.format
                        [ DF.yearNumber
                        , DF.text "-"
                        , DF.monthNameAbbreviated
                        , DF.text "-"
                        , DF.dayOfMonthNumber
                        , DF.text "--"
                        , DF.hourMilitaryNumber
                        , DF.text "-"
                        , DF.minuteNumber
                        ]
                        Time.utc
                        model.time

                name =
                    "recurring-" ++ datePart ++ ".json"
            in
            ( model, File.Download.string name "application/json" jsonString )

        Load ->
            ( model
            , File.Select.file [ "application/json" ] BackupLoaded
            )

        BackupLoaded file ->
            let
                decodeContents string =
                    case Decode.decodeString decoder string of
                        Ok data ->
                            Task.succeed data

                        Err err ->
                            Task.fail err

                decoder =
                    Decode.field "checklists" (Decode.list Checklist.decoder)
            in
            ( model
            , Task.attempt BackupDataLoaded (File.toString file |> Task.andThen decodeContents)
            )

        BackupDataLoaded result ->
            case result of
                Ok checklists ->
                    let
                        newChecklists =
                            checklists |> List.map (\list -> ( list.id, list )) |> Dict.fromList

                        newModel =
                            { model | checklists = newChecklists }
                    in
                    ( newModel
                    , save newModel
                    )

                Err error ->
                    ( model, Cmd.none )



---- VIEW ----


viewResult : ModelResult -> Browser.Document Msg
viewResult modelResult =
    case modelResult of
        Ok model ->
            view model

        Err errorText ->
            { title = "Error - Checklist"
            , body = [ E.layout [] (errorDisplay errorText) ]
            }


errorDisplay : String -> Element msg
errorDisplay errorText =
    E.row [ E.width E.fill, E.centerY, E.spacing 30 ]
        [ E.el [ E.centerX ]
            (E.el
                [ Background.color (E.rgb255 230 230 230)
                , E.padding 20
                ]
                (E.text errorText)
            )
        ]


view : Model -> Browser.Document Msg
view model =
    let
        viewChecklist checklist =
            Html.li []
                [ Html.a [ Attr.href (Checklist.url checklist.id) ] [ Html.text checklist.name ]
                ]

        checklists =
            Dict.values model.checklists
                |> List.map viewChecklist

        headerStyle =
            Css.batch
                [ Css.padding (Css.px 20)
                , Css.borderBottom3 (Css.px 1) Css.solid (Css.hex "#eeeeee")
                , Css.backgroundColor (Css.hex "#1e2948")
                ]

        h1Style =
            Css.batch
                [ Css.margin Css.zero
                , Css.textDecoration Css.none
                ]

        linkStyle =
            Css.batch
                [ Css.textDecoration Css.none
                ]

        h2Style =
            Css.batch
                [ Css.margin Css.zero
                ]

        mainStyle =
            Css.batch
                [ Css.displayFlex
                , Css.flexDirection Css.column
                , Css.padding (Css.px 20)
                ]

        buttonStyle =
            Css.batch
                [ Css.marginTop (Css.px 10)
                , Css.border Css.zero
                , Css.padding (Css.px 5)
                , Css.backgroundColor (Css.hex "#cccccc")
                ]
    in
    toUnstyledDocument <|
        case model.page of
            HomePage ->
                { title = "Recurring"
                , body =
                    [ Html.header [ Attr.css [ headerStyle ] ]
                        [ Html.a [ Attr.href "#/", Attr.css [ linkStyle ] ] [ Html.h1 [ Attr.css [ h1Style ] ] [ Html.text "Recurring" ] ]
                        ]
                    , Html.main_ [ Attr.css [ mainStyle ] ]
                        [ Html.ul [] checklists
                        , Html.input [ Attr.type_ "text", Events.onInput SetName, Attr.value model.name ] []
                        , Html.button
                            [ Events.onClick AddChecklist
                            , Attr.css [ buttonStyle ]
                            ]
                            [ Html.text "Add Checklist" ]
                        , Html.button
                            [ Events.onClick Download
                            , Attr.css [ buttonStyle ]
                            ]
                            [ Html.text "Download" ]
                        , Html.button
                            [ Events.onClick Load
                            , Attr.css [ buttonStyle ]
                            ]
                            [ Html.text "Load/Restore" ]
                        ]
                    ]
                }

            ChecklistPage checklistId ->
                case Dict.get checklistId model.checklists of
                    Just checklist ->
                        let
                            items =
                                Array.indexedMap viewItem checklist.items
                                    |> Array.toList

                            checked item =
                                case item.checked of
                                    Just _ ->
                                        True

                                    Nothing ->
                                        False

                            viewLink link =
                                Html.li []
                                    [ Html.a [ Attr.href link.url ] [ Html.text link.name ]
                                    ]

                            viewItem index item =
                                Html.li []
                                    [ Html.label []
                                        [ Html.input
                                            [ Attr.type_ "checkbox"
                                            , Events.onCheck (CheckItem checklistId index)
                                            , Attr.checked (checked item)
                                            ]
                                            []
                                        , Html.text item.name
                                        ]
                                    , Html.ul [] (Array.map viewLink item.links |> Array.toList)
                                    ]
                        in
                        { title = checklist.name ++ " - Recurring"
                        , body =
                            [ Html.header [ Attr.css [ headerStyle ] ]
                                [ Html.a [ Attr.href "#/", Attr.css [ linkStyle ] ]
                                    [ Html.h1 [ Attr.css [ h1Style ] ] [ Html.text "Recurring" ]
                                    ]
                                ]
                            , Html.main_ [ Attr.css [ mainStyle ] ]
                                [ Html.h2 [ Attr.css [ h2Style ] ] [ Html.text checklist.name ]
                                , Html.ul [] items
                                , Html.input [ Attr.type_ "text", Events.onInput SetName, Attr.value model.name ] []
                                , Html.button
                                    [ Events.onClick (AddItem checklist.id)
                                    , Attr.css [ buttonStyle ]
                                    ]
                                    [ Html.text "Add Item" ]
                                ]
                            ]
                        }

                    Nothing ->
                        { title = "404 - Page Not Found"
                        , body = [ Html.text "404" ]
                        }


toUnstyledDocument : { title : String, body : List (Html msg) } -> Browser.Document msg
toUnstyledDocument { title, body } =
    { title = title
    , body = [ Html.toUnstyled (Html.div [] body) ]
    }



---- PORTS ----


port outPort : Encode.Value -> Cmd msg


save : Model -> Cmd msg
save model =
    let
        portMsg =
            Encode.object
                [ ( "type", Encode.string "save" )
                , ( "data", encodeData model )
                ]
    in
    outPort portMsg



---- PROGRAM ----


main : Program Flags ModelResult Msg
main =
    Browser.application
        { init = initResult
        , update = updateResult
        , view = viewResult
        , subscriptions = always (Time.every (60 * 1000) Tick)
        , onUrlChange = UrlChange
        , onUrlRequest = UrlRequest
        }
