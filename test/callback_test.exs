defmodule MockCallback do
  use GenServer
  require Logger
  @behaviour GoogleSheets.Callback

  def start_link(parent_pid) do
    GenServer.start_link __MODULE__, parent_pid, name: :mock_callback
  end

  def on_loaded(id, data) do
    Logger.debug "on_loaded #{id}"
    GenServer.cast :mock_callback, {:loaded, id}
    data
  end

  def on_saved(id, _data) do
    Logger.debug "on_saved #{id}"
    GenServer.cast :mock_callback, {:saved, id}
  end

  def on_unchanged(id) do
    Logger.debug "on_unchanged #{id}"
    GenServer.cast :mock_callback, {:unchanged, id}
  end

  def handle_cast(msg, parent_pid) do
    send parent_pid, msg
    {:noreply, parent_pid}
  end
end

defmodule CallbackTest do

  use ExUnit.Case
  require Logger

  @test_pid nil

  test "Test updater process" do
    Logger.debug "#{inspect self}"
    cfg = [
      id: :callback_test,
      sheets: ["KeyValue"],
      poll_delay_seconds: 5,
      callback_module: MockCallback,
      loader_init: [module: GoogleSheets.Loader.FileSystem, src: "priv/data"],
      loader_poll: [module: GoogleSheets.Loader.Docs, src: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"]
    ]

    {:ok, _mock_pid} = MockCallback.start_link self
    {:ok, _updater_pid} = GoogleSheets.Updater.start_link(cfg, [])

    assert_receive {:loaded, :callback_test}, 50_000
    assert_receive {:saved, :callback_test}, 50_000
    assert_receive {:unchanged, :callback_test}, 50_000
  end
end
