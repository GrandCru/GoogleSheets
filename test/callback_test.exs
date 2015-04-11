defmodule MockCallbackHandler do

  @behaviour GoogleSheets.Callback

  def on_loaded(id, data) do
    send :callback_test, {:loaded, id}
    data
  end

  def on_saved(id, _data) do
    send :callback_test, {:saved, id}
  end

  def on_unchanged(id) do
    send :callback_test, {:unchanged, id}
  end
end

defmodule CallbackTest do

  use ExUnit.Case
  require Logger

  test "Test updater process" do
    Process.register self, :callback_test

    cfg = [
      id: :callback_spreadsheet,
      sheets: ["KeyValue"],
      poll_delay_seconds: 5,
      callback_module: MockCallbackHandler,
      loader_init: [module: GoogleSheets.Loader.FileSystem, dir: "priv/data"],
      loader_poll: [module: GoogleSheets.Loader.Docs, url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"]
    ]
    {:ok, _updater_pid} = GoogleSheets.Updater.start_link(cfg)

    assert_receive {:loaded, :callback_spreadsheet}, 50_000
    assert_receive {:saved, :callback_spreadsheet}, 50_000
    assert_receive {:unchanged, :callback_spreadsheet}, 50_000
  end
end
