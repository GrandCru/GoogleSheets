defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger

  alias GoogleSheets.Loader.Docs
  alias GoogleSheets.SpreadSheetData

  @url "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"

  test "Fetch all sheets" do
    assert {updated, %SpreadSheetData{} = spreadsheet} = Docs.load [], nil, [src: @url]

    assert updated != nil
    assert spreadsheet.hash == "0c55fcbcb0f6480df230bf6e7cedd7ce"
    assert length(spreadsheet.sheets) == 4
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "Fetch sheets with filtering" do
    assert {updated, %SpreadSheetData{} = spreadsheet} = Docs.load ["KeyValue", "KeyTable"], nil, [src: @url]

    assert updated != nil
    assert spreadsheet.hash == "42e023ea61cc1131fc79b94084aac247"
    assert length(spreadsheet.sheets) == 2
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "fetch invalid url" do
    assert_raise MatchError, fn -> Docs.load [], nil, [src: "http://www.example.org/invalid_key"] end
  end

  test "Test non existent sheet" do
    assert_raise MatchError, fn -> Docs.load ["KeyValue", "NonExistingSheet"], nil, [src: @url] end
  end


end