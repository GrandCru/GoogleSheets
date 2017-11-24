defmodule FileSystemTest do
  use ExUnit.Case, async: true

  require Logger

  alias GoogleSheets.Loader.FileSystem

  test "Load sheets using Application.app_dir" do
    config = [dir: {:google_sheets, "priv/data"}]
    assert {:ok, version, worksheets} = FileSystem.load nil, :spreadsheet_id, config
    assert version == "0ae38b918ed5e4bd76e7c65febb7bbc1ce28b70b"
    assert length(worksheets) == 4
  end

  test "Load all sheets" do
    config = [dir: "priv/data"]
    assert {:ok, version, worksheets} = FileSystem.load nil, :spreadsheet_id, config

    assert version == "0ae38b918ed5e4bd76e7c65febb7bbc1ce28b70b"
    assert length(worksheets) == 4
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "Ignored" end)

    assert {:ok, :unchanged} = FileSystem.load version, :spreadsheet_id, config
  end

  test "Load specified sheets" do
    config = [dir: "priv/data", sheets: ["KeyValue", "KeyTable", "Ignored"], ignored_sheets: ["Ignored"]]

    assert {:ok, version, worksheets} = FileSystem.load nil, :spreadsheet_id, config
    assert version == "1a714b244a64501fd2c51f95f38f495b0e4f111f"
    assert length(worksheets) == 2
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(worksheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(worksheets, fn(x) -> x.name == "Ignored" end)

    assert {:ok, :unchanged} = FileSystem.load version, :spreadsheet_id, config
  end

  test "Test nonexistent sheets" do
    assert {:error, _reason} = FileSystem.load nil, :spreadsheet_id, [dir: "priv/data", sheets: ["KeyValue", "NonExistingSheet"]]
  end

  test "Test invalid path" do
    assert {:error, _reason} = FileSystem.load nil, :spreadsheet_id, [dir: "this/path/doesnt/exist", sheets: ["KeyValue"]]
  end

end
