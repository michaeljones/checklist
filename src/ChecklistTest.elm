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
                        , refresh = Checklist.Daily
                        , items =
                            Array.fromList
                                [ { name = "Item 1", checked = Nothing }
                                , { name = "Item 2", checked = Just twoHoursAgo }
                                , { name = "Item 3", checked = Just fiveThisMorning }
                                , { name = "Item 4", checked = Just twoThisMorning }
                                , { name = "Item 5", checked = Just overOneDayAgo }
                                , { name = "Item 6", checked = Just almostFiveDaysAgo }
                                , { name = "Item 7", checked = Just almostFiveDaysAgo }
                                ]
                        }

                    twoHoursAgo =
                        Parts 2019 Time.Mar 30 16 30 0 0 |> partsToPosix Time.utc

                    fiveThisMorning =
                        Parts 2019 Time.Mar 30 5 0 0 0 |> partsToPosix Time.utc

                    twoThisMorning =
                        Parts 2019 Time.Mar 30 2 0 0 0 |> partsToPosix Time.utc

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
                                    , { name = "Item 3", checked = Just fiveThisMorning }
                                    , { name = "Item 4", checked = Nothing }
                                    , { name = "Item 5", checked = Nothing }
                                    , { name = "Item 6", checked = Nothing }
                                    , { name = "Item 7", checked = Nothing }
                                    ]
                        }
        , test "refreshes list on completion" <|
            \() ->
                let
                    checklist =
                        { id = 1
                        , name = "Test List"
                        , refresh = Checklist.OnCompletion
                        , items =
                            Array.fromList
                                [ { name = "Item 1", checked = Just twoHoursAgo }
                                , { name = "Item 2", checked = Just twoHoursAgo }
                                , { name = "Item 3", checked = Just fiveThisMorning }
                                , { name = "Item 4", checked = Just twoThisMorning }
                                , { name = "Item 5", checked = Just overOneDayAgo }
                                , { name = "Item 6", checked = Just almostFiveDaysAgo }
                                , { name = "Item 7", checked = Just almostFiveDaysAgo }
                                ]
                        }

                    twoHoursAgo =
                        Parts 2019 Time.Mar 30 16 30 0 0 |> partsToPosix Time.utc

                    fiveThisMorning =
                        Parts 2019 Time.Mar 30 5 0 0 0 |> partsToPosix Time.utc

                    twoThisMorning =
                        Parts 2019 Time.Mar 30 2 0 0 0 |> partsToPosix Time.utc

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
                                    , { name = "Item 2", checked = Nothing }
                                    , { name = "Item 3", checked = Nothing }
                                    , { name = "Item 4", checked = Nothing }
                                    , { name = "Item 5", checked = Nothing }
                                    , { name = "Item 6", checked = Nothing }
                                    , { name = "Item 7", checked = Nothing }
                                    ]
                        }
        , test "doesn't refresh unfinished list" <|
            \() ->
                let
                    checklist =
                        { id = 1
                        , name = "Test List"
                        , refresh = Checklist.OnCompletion
                        , items =
                            Array.fromList
                                [ { name = "Item 1", checked = Just twoHoursAgo }
                                , { name = "Item 2", checked = Just twoHoursAgo }
                                , { name = "Item 3", checked = Nothing }
                                , { name = "Item 4", checked = Just twoThisMorning }
                                , { name = "Item 5", checked = Just overOneDayAgo }
                                , { name = "Item 6", checked = Just almostFiveDaysAgo }
                                , { name = "Item 7", checked = Just almostFiveDaysAgo }
                                ]
                        }

                    twoHoursAgo =
                        Parts 2019 Time.Mar 30 16 30 0 0 |> partsToPosix Time.utc

                    fiveThisMorning =
                        Parts 2019 Time.Mar 30 5 0 0 0 |> partsToPosix Time.utc

                    twoThisMorning =
                        Parts 2019 Time.Mar 30 2 0 0 0 |> partsToPosix Time.utc

                    overOneDayAgo =
                        Parts 2019 Time.Mar 29 18 29 0 0 |> partsToPosix Time.utc

                    almostFiveDaysAgo =
                        Parts 2019 Time.Mar 25 18 35 0 0 |> partsToPosix Time.utc

                    now =
                        Parts 2019 Time.Mar 30 18 30 0 0 |> partsToPosix Time.utc
                in
                Checklist.refresh now checklist
                    |> Expect.equal checklist
        ]
