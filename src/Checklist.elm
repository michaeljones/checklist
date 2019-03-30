module Checklist exposing
    ( Checklist
    , Id
    , Item
    , addItem
    , decoder
    , encode
    , new
    , refresh
    , setItem
    , url
    )

import Array exposing (Array)
import Iso8601
import Json.Decode as Decode
import Json.Encode as Encode
import Time exposing (Posix)
import Time.Extra


type alias Checklist =
    { id : Id
    , name : String
    , items : Array Item
    }


type alias Id =
    Int


type alias Item =
    { name : String
    , checked : Maybe Posix
    }


url : Id -> String
url id =
    "/checklists/" ++ String.fromInt id


new : Id -> String -> Checklist
new id name =
    { id = id
    , name = name
    , items = Array.empty
    }


addItem : String -> Checklist -> Checklist
addItem name checklist =
    { checklist | items = Array.push { name = name, checked = Nothing } checklist.items }


setItem : Int -> Maybe Posix -> Checklist -> Checklist
setItem index checked checklist =
    let
        items =
            Array.get index checklist.items
                |> Maybe.map (\item -> { item | checked = checked })
                |> Maybe.map (\item -> Array.set index item checklist.items)
                |> Maybe.withDefault checklist.items
    in
    { checklist | items = items }


refresh : Posix -> Checklist -> Checklist
refresh time checklist =
    let
        items =
            Array.map refreshItem checklist.items

        refreshItem item =
            case item.checked of
                Nothing ->
                    item

                Just checkedTime ->
                    if daysOld checkedTime >= 1 then
                        { item | checked = Nothing }

                    else
                        item

        daysOld checkedTime =
            Time.Extra.diff Time.Extra.Day Time.utc checkedTime time
    in
    { checklist | items = items }



---- JSON ----


decoder : Decode.Decoder Checklist
decoder =
    let
        itemDecoder =
            Decode.map2 Item
                (Decode.field "name" Decode.string)
                (Decode.field "checked" (Decode.maybe Iso8601.decoder))
    in
    Decode.map3 Checklist
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "items" (Decode.array itemDecoder))


encode : Checklist -> Encode.Value
encode checklist =
    let
        itemEncoder item =
            Encode.object
                [ ( "name", Encode.string item.name )
                , ( "checked", Maybe.map Iso8601.encode item.checked |> Maybe.withDefault Encode.null )
                ]
    in
    Encode.object
        [ ( "id", Encode.int checklist.id )
        , ( "name", Encode.string checklist.name )
        , ( "items", Encode.array itemEncoder checklist.items )
        ]
