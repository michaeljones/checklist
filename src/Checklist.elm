module Checklist exposing (Checklist, Id, Item, addItem, empty, url)


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


empty : Id -> Checklist
empty id =
    { id = id
    , name = "New Checklist"
    , items = []
    }


addItem : Checklist -> Checklist
addItem checklist =
    { checklist | items = checklist.items ++ [ { name = "New Item", checked = False } ] }
