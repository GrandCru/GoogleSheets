defmodule UpdaterTestMockParser do
  @behaviour GoogleSheets.Parser
  def parse(id, worksheets) do
    send :updater_test_process, {:parsed, id}
    {:ok, worksheets}
  end
end

defmodule UpdaterTest do

  use ExUnit.Case
  require Logger

  test "Test updater process" do
    Process.register self, :updater_test_process

    cfg = [
      id: :updater_test_spreadsheet,
      sheets: ["KeyValue"],
      parser: UpdaterTestMockParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 1,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ]

    # Assert data has been loaded,
    # first by file system loader in the init phase of updater process
    # and immediately after by configure loader module.
    {:ok, _updater_pid} = GoogleSheets.Updater.start_link(cfg)
    assert_receive {:parsed, :updater_test_spreadsheet}, 120_000
    assert_receive {:parsed, :updater_test_spreadsheet}, 120_000

    # Trigger manual update
    assert {:ok, _msg} = GoogleSheets.update :updater_test_spreadsheet
  end

end
