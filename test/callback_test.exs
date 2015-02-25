defmodule CallbackTest do
  use ExUnit.Case
  require Logger

  @test_pid nil

  @behaviour GoogleSheets.Callback
  def on_data_loaded(id, data) do
    data
  end

  def on_data_saved(id) do
  end

  test "Test updater process" do
    cfg = [
      id: :callback_test,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      worksheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      delay: 10,
      callback: CallbackTest
    ]
  end

end

