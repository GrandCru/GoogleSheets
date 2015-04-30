defmodule GetTest do

  use ExUnit.Case
  require Logger

  test "Test await and get" do
    key = GoogleSheets.await_key :multiple_worksheets
    spreadsheet = GoogleSheets.get key
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end
end