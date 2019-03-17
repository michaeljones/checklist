module Checklist exposing (Checklist, Id, Item, addItem, decoder, encode, new, url)

import Json.Decode as Decode
import Json.Encode as Encode


type alias Checklist =
    { id : Id
    , name : String
    , items : List Item
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
    , items = []
    }


addItem : String -> Checklist -> Checklist
addItem name checklist =
    { checklist | items = checklist.items ++ [ { name = name, checked = False } ] }



---- JSON ----


decoder : Decode.Decoder Checklist
decoder =
    let
        itemDecoder =
            Decode.map2 Item
                (Decode.field "name" Decode.string)
                (Decode.succeed False)
    in
    Decode.map3 Checklist
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "items" (Decode.list itemDecoder))


encode : Checklist -> Encode.Value
encode checklist =
    let
        itemEncoder item =
            Encode.object
                [ ( "name", Encode.string item.name ) ]
    in
    Encode.object
        [ ( "id", Encode.int checklist.id )
        , ( "name", Encode.string checklist.name )
        , ( "items", Encode.list itemEncoder checklist.items )
        ]
