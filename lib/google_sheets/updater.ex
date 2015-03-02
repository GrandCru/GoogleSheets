defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  alias GoogleSheets.LoaderData

  def start_link(config, options \\ []) do
    GenServer.start_link(__MODULE__, config, options)
  end

  def init(config) do
    # Send the first poll request immediately
    Process.send_after self(), :update, 0
    {:ok, config}
  end

  def handle_info(:update, config) do
    handle_update config
    {:noreply, config}
  end

  # Internal implementation
  defp handle_update(config) do
    Logger.debug "Requesting CSV data for spreadsheet #{config[:id]}"
    handle_load config, %LoaderData{key: config[:key], sheets: config[:worksheets]}
  end

  defp handle_load(config, %LoaderData{:status => :ok} = data) do
    try do
      data = loaded_callback config, data
      :ets.insert ets_table, {config[:id], data}
      saved_callback config, data
    rescue
      e ->
        stacktrace = System.stacktrace
        Logger.error "Failed to parse and/or store config, reason: #{inspect e} #{inspect stacktrace}"
    end
    schedule_update config[:delay]
  end
  defp handle_load(config, %LoaderData{:status => :up_to_date} = data) do
    schedule_update config[:delay]
  end

  # If delay has been configured to 0, the update will be done only once.
  defp schedule_update(0) do
    Logger.debug "Stopping scheduled updates"
  end
  defp schedule_update(delay) do
    Logger.debug "Next update in #{delay} seconds"
    Process.send_after self(), :update, delay * 1000
  end

  # Let the host application do what ever they want with the data
  defp loaded_callback(config, data) do
    if config[:callback] != nil do
      data = config[:callback].on_data_loaded config[:id], data
    end
    data
  end

  # Notify that there is new data available
  defp saved_callback(config, data) do
    if config[:callback] != nil do
      config[:callback].on_data_saved config[:id], data
    end
  end

  defp ets_table do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    ets_table
  end

end
