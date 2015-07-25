defmodule UpdaterTestMockParser do
  @behaviour GoogleSheets.Parser
  def parse(id, _version, worksheets) do
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
    {:ok, _updater_pid} = GoogleSheets.Updater.start_link cfg
    assert_receive {:parsed, :updater_test_spreadsheet}, 120_000
    assert_receive {:parsed, :updater_test_spreadsheet}, 120_000

    # Test API
    assert true == GoogleSheets.has_version? :updater_test_spreadsheet

    # Request latest versions
    assert {:ok, version_key} = GoogleSheets.latest_key :updater_test_spreadsheet
    assert ^version_key = GoogleSheets.latest_key! :updater_test_spreadsheet
    assert {:ok, ^version_key, data} = GoogleSheets.latest :updater_test_spreadsheet
    assert {^version_key, ^data} = GoogleSheets.latest! :updater_test_spreadsheet

    # Request specfic version
    assert {:ok, ^data} = GoogleSheets.fetch version_key
    assert ^data = GoogleSheets.fetch! version_key

    # Trigger manual update
    assert {:ok, _msg} = GoogleSheets.update :updater_test_spreadsheet
  end

  test "ETS lookup for latest key" do
    Process.register self, :updater_test_process

    cfg1 = [
      id: :sheet_1,
      sheets: ["KeyValue"],
      parser: UpdaterTestMockParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 1,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ]

    cfg2 = [
      id: :sheet_2,
      sheets: ["KeyTable"],
      parser: UpdaterTestMockParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 1,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ]

    {:ok, _updater_pid} = GoogleSheets.Updater.start_link cfg1
    {:ok, _updater_pid} = GoogleSheets.Updater.start_link cfg2

    version_key_1 = GoogleSheets.latest_key! :sheet_1
    version_key_2 = GoogleSheets.latest_key! :sheet_2
    assert version_key_1 != version_key_2

    {:ok, _msg} = GoogleSheets.update :sheet_1

    version_key_1 = GoogleSheets.latest_key! :sheet_1
    version_key_2 = GoogleSheets.latest_key! :sheet_2
    assert version_key_1 != version_key_2

    # This update will get us same version key on next assertion
    {:ok, _msg} = GoogleSheets.update :sheet_2

    version_key_1 = GoogleSheets.latest_key! :sheet_1
    version_key_2 = GoogleSheets.latest_key! :sheet_2

    # This assertion will fail, but IMO it shouldn't
    assert version_key_1 != version_key_2
  end

end
