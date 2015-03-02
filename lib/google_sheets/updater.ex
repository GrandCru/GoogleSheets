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
    data = %LoaderData{key: config[:key], included_sheets: config[:worksheets], last_updated: last_updated(:ets.lookup(ets_table, config[:id])) }
    handle_load config, GoogleSheets.Loader.load data
  end

  defp last_updated([]), do: nil
  defp last_updated([{_id, last_updated, _}]), do: last_updated

  defp handle_load(config, %LoaderData{:status => :ok} = data) do
    try do
      persisted = loaded_callback config, data.spreadsheet
      :ets.insert ets_table, {config[:id], data.last_updated, persisted}
      saved_callback config, persisted
    rescue
      e ->
        stacktrace = System.stacktrace
        Logger.error "Failed to parse and/or store config, reason: #{inspect e} #{inspect stacktrace}"
    end
    schedule_update config[:delay]
  end
  defp handle_load(config, %LoaderData{:status => :up_to_date} = data) do
    on_up_to_date config
    schedule_update config[:delay]
  end

  # If delay has been configured to 0, the update will be done only once.
  defp schedule_update(0) do
    Logger.debug "Stopping scheduled updates"
  end
  defp schedule_update(delay) do
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

  # Notify that update
  defp on_up_to_date(config) do
    if config[:callback] != nil do
      config[:callback].on_up_to_date config[:id]
    end
  end

  defp ets_table do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    ets_table
  end

end
