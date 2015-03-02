defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger
  alias GoogleSheets.LoaderData

  @document_key "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"

  test "Fetch all sheets" do

    response = GoogleSheets.Loader.load %LoaderData{key: @document_key}

    assert response.status == :ok
    assert response.last_updated != nil
    assert response.spreadsheet.hash == "0c55fcbcb0f6480df230bf6e7cedd7ce"
    assert length(response.spreadsheet.sheets) == 4
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)

  end

  test "Fetch sheets with filtering" do
    response = GoogleSheets.Loader.load %LoaderData{key: @document_key, included_sheets: ["KeyValue", "KeyTable", "KeyIndexTable"]}
    assert response.status == :ok
    assert response.last_updated != nil
    assert response.spreadsheet.hash == "a1cab0e42272d106576bdf6782b02334"
    assert length(response.spreadsheet.sheets) == 3
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(response.spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "fetch invalid url" do
    response = GoogleSheets.Loader.load %LoaderData{key: "invalid_key"}
    assert response.status == :error
  end

end
