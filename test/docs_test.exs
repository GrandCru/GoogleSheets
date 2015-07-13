defmodule DocsTest do
  use ExUnit.Case

  require Logger

  alias GoogleSheets.Loader.Docs
  alias GoogleSheets.SpreadSheetData

  @url "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"

  test "Fetch all sheets" do
    config = [url: @url]
    assert {:ok, %SpreadSheetData{} = spreadsheet} = Docs.load nil, config

    assert spreadsheet.version == "a3d4c20066a7f5ebebde18fc4f7ad1ecd6cb96ac"
    assert length(spreadsheet.sheets) == 4
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)

    assert {:ok, :unchanged} = Docs.load spreadsheet.version, config
  end

  test "Load specific sheets" do
    config = [url: @url, sheets: ["KeyValue", "KeyTable"]]
    assert {:ok, %SpreadSheetData{} = spreadsheet} = Docs.load nil, config

    assert spreadsheet.version == "a3d4c20066a7f5ebebde18fc4f7ad1ecd6cb96ac"
    assert length(spreadsheet.sheets) == 2
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)

    assert {:ok, :unchanged} = Docs.load spreadsheet.version, config
  end

  test "fetch invalid url" do
    assert_raise MatchError, fn -> Docs.load nil, [url: "http://www.example.org/invalid_key"] end
  end

  test "Test non existent sheet" do
    assert {:error, _reason} = Docs.load nil, [url: @url, sheets: ["KeyValue", "NonExistingSheet"]]
  end

end