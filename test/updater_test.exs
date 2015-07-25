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

    cfg1 = [
      id: :sheet1,
      sheets: ["KeyValue"],
      parser: UpdaterTestMockParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 1,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ]
    cfg2 = [
      id: :sheet2,
      sheets: ["KeyTable"],
      parser: UpdaterTestMockParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 1,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ]

    # Assert data has been loaded,
    # first by file system loader in the init phase of updater process
    # and immediately after by configure loader module.
    {:ok, _pid1} = GoogleSheets.Updater.start_link cfg1
    assert_receive {:parsed, :sheet1}, 120_000
    assert_receive {:parsed, :sheet1}, 120_000

    # Do the same for the second spreadsheet
    {:ok, _pid2} = GoogleSheets.Updater.start_link cfg2
    assert_receive {:parsed, :sheet2}, 120_000
    assert_receive {:parsed, :sheet2}, 120_000

    # Test API
    assert true == GoogleSheets.has_version? :sheet1
    assert true == GoogleSheets.has_version? :sheet2

    # Request latest versions
    assert {:ok, sheet1_version_key} = GoogleSheets.latest_key :sheet1
    assert ^sheet1_version_key = GoogleSheets.latest_key! :sheet1
    assert {:ok, ^sheet1_version_key, data} = GoogleSheets.latest :sheet1
    assert {^sheet1_version_key, ^data} = GoogleSheets.latest! :sheet1

    # Request specfic version
    assert {:ok, ^data} = GoogleSheets.fetch sheet1_version_key
    assert ^data = GoogleSheets.fetch! sheet1_version_key

    # Trigger manual update
    assert {:ok, _msg} = GoogleSheets.update :sheet1

    # Assert that sheet 1 and two have different keys
    assert {:ok, sheet2_version_key} = GoogleSheets.latest_key :sheet2
    assert sheet1_version_key != sheet2_version_key

    # Check the ETS entries
    ets_entries = :ets.tab2list :google_sheets

    assert 6 == length ets_entries
    assert 1 == Enum.count ets_entries, fn {key, _value} -> key == sheet1_version_key end
    assert 1 == Enum.count ets_entries, fn {key, _value} -> key == sheet2_version_key end
  end
end
