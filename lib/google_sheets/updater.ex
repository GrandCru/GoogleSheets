defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  alias GoogleSheets.LoaderConfig
  alias GoogleSheets.SpreadSheetData

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
    settings = %LoaderConfig{key: config[:key], last_updated: last_updated(config), included: config[:included], excluded: config[:excluded] }
    handle_load config, GoogleSheets.Loader.load settings
  end

  defp last_updated(config) do
    case :ets.lookup ets_table, config[:id] do
      [{_id, last_updated, _}] ->
        last_updated
      _ ->
        nil
    end
  end

  defp handle_load(config, {updated, %SpreadSheetData{} = spreadsheet}) do
    data = loaded_callback config, spreadsheet
    :ets.insert ets_table, {config[:id], updated, data}
    saved_callback config, data
    schedule_update config[:delay]
  end
  defp handle_load(config, :unchanged) do
    on_unchanged config
    schedule_update config[:delay]
  end
  defp handle_load(config, :error) do
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
      data = config[:callback].on_loaded config[:id], data
    end
    data
  end

  # Notify that there is new data available
  defp saved_callback(config, data) do
    if config[:callback] != nil do
      config[:callback].on_saved config[:id], data
    end
  end

  # Notify that the data was unchanged
  defp on_unchanged(config) do
    if config[:callback] != nil do
      config[:callback].on_unchanged config[:id]
    end
  end

  defp ets_table do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    ets_table
  end

end
