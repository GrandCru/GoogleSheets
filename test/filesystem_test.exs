defmodule FileSystemTest do
  use ExUnit.Case

  require Logger

  alias GoogleSheets.Loader.FileSystem
  alias GoogleSheets.SpreadSheetData

  test "Load all sheets" do
    assert {version, %SpreadSheetData{} = spreadsheet} = FileSystem.load [], nil, [dir: "priv/data"]

    assert spreadsheet.hash == "0c55fcbcb0f6480df230bf6e7cedd7ce"
    assert length(spreadsheet.sheets) == 4
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)

    assert :unchanged = FileSystem.load [], version, [dir: "priv/data"]
  end

  test "Load specified sheets" do
    assert {version, %SpreadSheetData{} = spreadsheet} = FileSystem.load ["KeyValue", "KeyTable"], nil, [dir: "priv/data"]
    assert spreadsheet.hash == "42e023ea61cc1131fc79b94084aac247"
    assert length(spreadsheet.sheets) == 2
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(spreadsheet.sheets, fn(x) -> x.name == "Ignored" end)

    assert :unchanged = FileSystem.load ["KeyValue", "KeyTable"], version, [dir: "priv/data"]
  end

  test "Test nonexistent sheets" do
    assert_raise MatchError, fn -> FileSystem.load ["KeyValue", "NonExistingSheet"], nil, [dir: "priv/data"] end
  end

  test "Test invalid path" do
    assert_raise MatchError, fn -> FileSystem.load ["KeyValue", "NonExistingSheet"], nil, [dir: "this/path/doesnt/exist"] end
  end

end