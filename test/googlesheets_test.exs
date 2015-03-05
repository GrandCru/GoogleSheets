defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger

  alias GoogleSheets.LoaderConfig
  alias GoogleSheets.SpreadSheetData

  @document_key "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"

  test "Fetch all sheets" do
    config = %LoaderConfig{key: @document_key, included: nil, excluded: nil}
    assert {updated, %SpreadSheetData{} = spreadsheet} = GoogleSheets.Loader.load config

    assert updated != nil
    assert spreadsheet.hash == "0c55fcbcb0f6480df230bf6e7cedd7ce"
    assert length(spreadsheet.sheets) == 4
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "Fetch sheets with filtering" do
    config = %LoaderConfig{key: @document_key, included: ["KeyValue", "KeyTable", "KeyIndexTable"], excluded: ["KeyIndexTable"]}
    assert {updated, %SpreadSheetData{} = spreadsheet} =  GoogleSheets.Loader.load config

    assert updated != nil
    assert spreadsheet.hash == "42e023ea61cc1131fc79b94084aac247"
    assert length(spreadsheet.sheets) == 2
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "fetch invalid url" do
    config = %LoaderConfig{key: "invalid_key", included: nil, excluded: nil}
    assert_raise MatchError, fn -> GoogleSheets.Loader.load config end
  end

end
