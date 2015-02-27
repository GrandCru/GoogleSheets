
defmodule MockCallback do
  use GenServer
  require Logger
  @behaviour GoogleSheets.Callback

  def start_link(parent_pid) do
    GenServer.start_link __MODULE__, parent_pid, name: :mock_callback
  end

  def on_data_loaded(id, data) do
    GenServer.cast :mock_callback, {:loaded, id}
    data
  end

  def on_data_saved(id, data) do
    GenServer.cast :mock_callback, {:saved, id}
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
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      worksheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      delay: 10,
      callback: MockCallback
    ]
    {:ok, _mock_pid} = MockCallback.start_link self
    {:ok, _updater_pid} = GoogleSheets.Updater.start_link(cfg, [])

    assert_receive {:loaded, :callback_test}, 50_000
    assert_receive {:saved, :callback_test}, 50_000
  end
end

