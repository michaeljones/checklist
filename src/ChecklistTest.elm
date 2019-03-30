module ChecklistTest exposing (all)

import Array
import Checklist
import Expect
import Test exposing (..)
import Time
import Time.Extra exposing (Parts, partsToPosix)


all : Test
all =
    describe "refresh"
        [ test "refreshes empty list" <|
            \() ->
                let
                    checklist =
                        Checklist.new 1 "Test List"

                    time =
                        Time.millisToPosix 0
                in
                Checklist.refresh time checklist
                    |> Expect.equal checklist
        , test "refreshes list" <|
            \() ->
                let
                    checklist =
                        { id = 1
                        , name = "Test List"
                        , items =
                            Array.fromList
                                [ { name = "Item 1", checked = Nothing }
                                , { name = "Item 2", checked = Just twoHoursAgo }
                                , { name = "Item 3", checked = Just overOneDayAgo }
                                , { name = "Item 4", checked = Just almostFiveDaysAgo }
                                ]
                        }

                    twoHoursAgo =
                        Parts 2019 Time.Mar 30 16 30 0 0 |> partsToPosix Time.utc

                    overOneDayAgo =
                        Parts 2019 Time.Mar 29 18 29 0 0 |> partsToPosix Time.utc

                    almostFiveDaysAgo =
                        Parts 2019 Time.Mar 25 18 35 0 0 |> partsToPosix Time.utc

                    now =
                        Parts 2019 Time.Mar 30 18 30 0 0 |> partsToPosix Time.utc
                in
                Checklist.refresh now checklist
                    |> Expect.equal
                        { checklist
                            | items =
                                Array.fromList
                                    [ { name = "Item 1", checked = Nothing }
                                    , { name = "Item 2", checked = Just twoHoursAgo }
                                    , { name = "Item 3", checked = Nothing }
                                    , { name = "Item 4", checked = Nothing }
                                    ]
                        }
        ]
