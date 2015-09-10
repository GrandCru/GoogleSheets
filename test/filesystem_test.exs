defmodule FileSystemTest do
  use ExUnit.Case

  require Logger

  alias GoogleSheets.Loader.FileSystem

  test "Loadd sheets using Application.app_dir" do
    config = [dir: {:google_sheets, "priv/data"}]
    assert {:ok, version, worksheets} = FileSystem.load nil, config
    assert version == "aebc5cd5aae29114bf28150d3d5609e19b2481c8"
    assert length(worksheets) == 4
  end

  test "Load all sheets" do
    config = [dir: "priv/data"]
    assert {:ok, version, worksheets} = FileSystem.load nil, config

    assert version == "aebc5cd5aae29114bf28150d3d5609e19b2481c8"
    assert length(worksheets) == 4
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyTable" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyIndexTable" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "Ignored" end)

    assert {:ok, :unchanged} = FileSystem.load version, config
  end

  test "Load specified sheets" do
    config = [dir: "priv/data", sheets: ["KeyValue", "KeyTable"]]

    assert {:ok, version, worksheets} = FileSystem.load nil, config
    assert version == "c0f5fc899f4e0f31528090b56aca30c4e4fd058f"
    assert length(worksheets) == 2
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyValue" end)
    assert Enum.any?(worksheets, fn(x) -> x.name == "KeyTable" end)
    refute Enum.any?(worksheets, fn(x) -> x.name == "KeyIndexTable" end)
    refute Enum.any?(worksheets, fn(x) -> x.name == "Ignored" end)

    assert {:ok, :unchanged} = FileSystem.load version, config
  end

  test "Test nonexistent sheets" do
    assert {:error, _reason} = FileSystem.load nil, [dir: "priv/data", sheets: ["KeyValue", "NonExistingSheet"]]
  end

  test "Test invalid path" do
    assert {:error, _reason} = FileSystem.load nil, [dir: "this/path/doesnt/exist", sheets: ["KeyValue"]]
  end

end