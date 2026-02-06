import checklist/data.{Checklist, Daily, Item, OnCompletion}
import gleam/option.{None, Some}
import gleeunit/should
import rada/date

pub fn refresh_empty_list_test() {
  let checklist = data.new(1, "Test List")
  let today = date.from_calendar_date(2019, date.Mar, 30)
  let result = data.refresh(checklist, today)
  should.equal(result, checklist)
}

pub fn refresh_daily_test() {
  // In the date-based model:
  // - Items checked today (Mar 30) should be kept
  // - Items checked before today should be reset
  let today = date.from_calendar_date(2019, date.Mar, 30)
  let yesterday = date.from_calendar_date(2019, date.Mar, 29)
  let five_days_ago = date.from_calendar_date(2019, date.Mar, 25)

  let checklist =
    Checklist(id: 1, name: "Test List", refresh_mode: Daily, items: [
      Item(name: "Item 1", checked: None, links: []),
      Item(name: "Item 2", checked: Some(today), links: []),
      Item(name: "Item 3", checked: Some(today), links: []),
      Item(name: "Item 4", checked: Some(today), links: []),
      Item(name: "Item 5", checked: Some(yesterday), links: []),
      Item(name: "Item 6", checked: Some(five_days_ago), links: []),
      Item(name: "Item 7", checked: Some(five_days_ago), links: []),
    ])

  let expected =
    Checklist(..checklist, items: [
      Item(name: "Item 1", checked: None, links: []),
      Item(name: "Item 2", checked: Some(today), links: []),
      Item(name: "Item 3", checked: Some(today), links: []),
      Item(name: "Item 4", checked: Some(today), links: []),
      Item(name: "Item 5", checked: None, links: []),
      Item(name: "Item 6", checked: None, links: []),
      Item(name: "Item 7", checked: None, links: []),
    ])

  data.refresh(checklist, today)
  |> should.equal(expected)
}

pub fn refresh_on_completion_test() {
  let today = date.from_calendar_date(2019, date.Mar, 30)
  let yesterday = date.from_calendar_date(2019, date.Mar, 29)
  let five_days_ago = date.from_calendar_date(2019, date.Mar, 25)

  let checklist =
    Checklist(id: 1, name: "Test List", refresh_mode: OnCompletion, items: [
      Item(name: "Item 1", checked: Some(today), links: []),
      Item(name: "Item 2", checked: Some(today), links: []),
      Item(name: "Item 3", checked: Some(today), links: []),
      Item(name: "Item 4", checked: Some(today), links: []),
      Item(name: "Item 5", checked: Some(yesterday), links: []),
      Item(name: "Item 6", checked: Some(five_days_ago), links: []),
      Item(name: "Item 7", checked: Some(five_days_ago), links: []),
    ])

  let expected =
    Checklist(..checklist, items: [
      Item(name: "Item 1", checked: None, links: []),
      Item(name: "Item 2", checked: None, links: []),
      Item(name: "Item 3", checked: None, links: []),
      Item(name: "Item 4", checked: None, links: []),
      Item(name: "Item 5", checked: None, links: []),
      Item(name: "Item 6", checked: None, links: []),
      Item(name: "Item 7", checked: None, links: []),
    ])

  data.refresh(checklist, today)
  |> should.equal(expected)
}

pub fn refresh_incomplete_on_completion_test() {
  let today = date.from_calendar_date(2019, date.Mar, 30)
  let yesterday = date.from_calendar_date(2019, date.Mar, 29)
  let five_days_ago = date.from_calendar_date(2019, date.Mar, 25)

  let checklist =
    Checklist(id: 1, name: "Test List", refresh_mode: OnCompletion, items: [
      Item(name: "Item 1", checked: Some(today), links: []),
      Item(name: "Item 2", checked: Some(today), links: []),
      Item(name: "Item 3", checked: None, links: []),
      Item(name: "Item 4", checked: Some(today), links: []),
      Item(name: "Item 5", checked: Some(yesterday), links: []),
      Item(name: "Item 6", checked: Some(five_days_ago), links: []),
      Item(name: "Item 7", checked: Some(five_days_ago), links: []),
    ])

  data.refresh(checklist, today)
  |> should.equal(checklist)
}
