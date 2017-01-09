defmodule UpdaterTestMockParser do
  @behaviour GoogleSheets.Parser
  def parse(id, worksheets) do
    send :test_updater_process, {:parsed, id}
    {:ok, worksheets}
  end
end

defmodule UpdaterTest do
  use ExUnit.Case, async: true

  require Logger

  @timeout 120_000
  @dir "priv/data"
  @url "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"

  test "Test updater process" do
    Process.register self(), :test_updater_process

    cfg1 = [ sheets: ["KeyValue"], parser: UpdaterTestMockParser, loader: GoogleSheets.Loader.Docs, poll_delay_seconds: 1, dir: @dir, url: @url ]
    cfg2 = [ sheets: ["KeyValue", "KeyTable"], parser: UpdaterTestMockParser, loader: GoogleSheets.Loader.Docs, poll_delay_seconds: 1, dir: @dir, url: @url ]

    # Assert data has been loaded, first by file system loader in the init phase of updater process
    # and immediately after by configured loader module.
    {:ok, _pid1} = GoogleSheets.Updater.start_link :sheet1, cfg1
    assert_receive {:parsed, :sheet1}, @timeout
    assert_receive {:parsed, :sheet1}, @timeout

    # Do the same for the second spreadsheet
    {:ok, _pid2} = GoogleSheets.Updater.start_link :sheet2, cfg2
    assert_receive {:parsed, :sheet2}, @timeout
    assert_receive {:parsed, :sheet2}, @timeout

    # Test API
    assert true == GoogleSheets.has_version? :sheet1
    assert true == GoogleSheets.has_version? :sheet2

    assert {:ok, sheet1_version} = GoogleSheets.latest_version :sheet1
    assert ^sheet1_version = GoogleSheets.latest_version! :sheet1

    assert {:ok, ^sheet1_version, data} = GoogleSheets.latest :sheet1
    assert {^sheet1_version, ^data} = GoogleSheets.latest! :sheet1

    assert {:ok, ^data} = GoogleSheets.latest_data :sheet1
    assert ^data = GoogleSheets.latest_data! :sheet1

    assert {:ok, ^data} = GoogleSheets.fetch sheet1_version
    assert ^data = GoogleSheets.fetch! sheet1_version

    # Trigger manual update request for a spreadsheet and make sure no changes are
    assert {:ok, :unchanged} = GoogleSheets.update :sheet1

    # Assert that sheet1 and sheet2 don't have same version keys
    assert {:ok, sheet2_version} = GoogleSheets.latest_version :sheet2
    assert sheet1_version != sheet2_version

    # Check the ETS entries
    ets_entries = :ets.tab2list :google_sheets

    assert 1 == Enum.count ets_entries, fn {key, %{}} -> key == :sheet1 end
    assert 1 == Enum.count ets_entries, fn {key, %{}} -> key == sheet1_version end
    assert 1 == Enum.count ets_entries, fn {key, %{}} -> key == :sheet2 end
    assert 1 == Enum.count ets_entries, fn {key, %{}} -> key == sheet1_version end
  end

end
