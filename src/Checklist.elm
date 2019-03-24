module Checklist exposing (Checklist, Id, Item, addItem, decoder, encode, new, setItem, url)

import Array exposing (Array)
import Json.Decode as Decode
import Json.Encode as Encode


type alias Checklist =
    { id : Id
    , name : String
    , items : Array Item
    }


type alias Id =
    Int


type alias Item =
    { name : String
    , checked : Bool
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
    { checklist | items = Array.push { name = name, checked = False } checklist.items }


setItem : Int -> Bool -> Checklist -> Checklist
setItem index checked checklist =
    let
        items =
            Array.get index checklist.items
                |> Maybe.map (\item -> { item | checked = checked })
                |> Maybe.map (\item -> Array.set index item checklist.items)
                |> Maybe.withDefault checklist.items
    in
    { checklist | items = items }



---- JSON ----


decoder : Decode.Decoder Checklist
decoder =
    let
        itemDecoder =
            Decode.map2 Item
                (Decode.field "name" Decode.string)
                (Decode.field "checked" Decode.bool)
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
                , ( "checked", Encode.bool item.checked )
                ]
    in
    Encode.object
        [ ( "id", Encode.int checklist.id )
        , ( "name", Encode.string checklist.name )
        , ( "items", Encode.array itemEncoder checklist.items )
        ]
