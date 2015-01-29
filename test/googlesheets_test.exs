defmodule GooglesheetsTest do
  use ExUnit.Case

  require Logger

  @document_key "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"

  test "fetch document url" do
    assert {:ok, data} = GoogleSheets.Loader.load @document_key
    assert Dict.has_key?(data, "KeyValue")
    assert Dict.has_key?(data, "KeyTable")
    assert Dict.has_key?(data, "KeyIndexTable")
  end

  test "fetch invalid url" do
    assert {:error, _} = GoogleSheets.Loader.load "aaaaaaaaaaaa"
  end

end
