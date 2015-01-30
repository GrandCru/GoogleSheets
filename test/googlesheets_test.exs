defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger

  @document_key "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"

  test "Fetch all sheets" do
    assert {:ok, data} = GoogleSheets.Loader.load @document_key
    assert Dict.has_key?(data, "KeyValue")
    assert Dict.has_key?(data, "KeyTable")
    assert Dict.has_key?(data, "KeyIndexTable")
    assert Dict.has_key?(data, "Ignored")
  end

  test "Fetch sheets with filtering" do
    assert {:ok, data} = GoogleSheets.Loader.load @document_key, ["KeyValue", "KeyTable", "KeyIndexTable"]
    assert Dict.has_key?(data, "KeyValue")
    assert Dict.has_key?(data, "KeyTable")
    assert Dict.has_key?(data, "KeyIndexTable")
    assert !Dict.has_key?(data, "Ignored")
  end

  test "fetch invalid url" do
    assert {:error, _} = GoogleSheets.Loader.load "aaaaaaaaaaaa"
  end

end
