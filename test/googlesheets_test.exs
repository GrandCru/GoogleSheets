defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger

  alias GoogleSheets.Loader.Docs
  alias GoogleSheets.SpreadSheetData

  @document_key "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"

  test "Fetch all sheets" do
    sheets = []
    opts = [key: @document_key]
    assert {updated, %SpreadSheetData{} = spreadsheet} = Docs.load sheets, nil, opts

    assert updated != nil
    assert spreadsheet.hash == "0c55fcbcb0f6480df230bf6e7cedd7ce"
    assert length(spreadsheet.sheets) == 4
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "Fetch sheets with filtering" do
    sheets = ["KeyValue", "KeyTable"]
    opts = [key: @document_key]
    assert {updated, %SpreadSheetData{} = spreadsheet} = Docs.load sheets, nil, opts

    assert updated != nil
    assert spreadsheet.hash == "42e023ea61cc1131fc79b94084aac247"
    assert length(spreadsheet.sheets) == 2
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "fetch invalid url" do
    assert_raise MatchError, fn -> Docs.load [], nil, [key: "invalid_key"] end
  end

end