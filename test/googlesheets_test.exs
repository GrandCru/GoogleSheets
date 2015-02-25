defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger

  @document_key "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"

  test "Fetch all sheets" do
    assert {:ok, data} = GoogleSheets.Loader.load @document_key

    assert data.hash == "0c55fcbcb0f6480df230bf6e7cedd7ce"
    assert length(data.sheets) == 4
    assert Enum.any?(data.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(data.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(data.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(data.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "Fetch sheets with filtering" do
    assert {:ok, data} = GoogleSheets.Loader.load @document_key, ["KeyValue", "KeyTable", "KeyIndexTable"]
    assert data.hash == "a1cab0e42272d106576bdf6782b02334"
    assert length(data.sheets) == 3
    assert Enum.any?(data.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(data.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(data.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(data.sheets, fn(x) -> x.name == "Ignored" end)
  end

  test "fetch invalid url" do
    assert {:error, _} = GoogleSheets.Loader.load "aaaaaaaaaaaa"
  end

end
