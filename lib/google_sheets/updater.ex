defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  alias GoogleSheets.LoaderConfig
  alias GoogleSheets.SpreadSheetData

  def start_link(config, options \\ []) do
    GenServer.start_link(__MODULE__, config, options)
  end

  def init(config) do
    # Just so that we don't restart quite as often in case google server is down or we have network problems
    if first_launch do
      Process.send_after self(), :update, 0
    else
      if config[:delay] <= 0 do
        Logger.debug "Subsequent restart for #{config[:id]}, configured delay #{config[:delay]} less or equal to 0, waiting still at least 30 seconds before polling again"
        schedule_update config, 30
      else
        Logger.debug "Subsequent restart for #{config[:id]}, waiting configured delay before polling again #{config[:delay]}"
        schedule_update config, config[:delay]
      end
    end
    {:ok, config}
  end

  def handle_info(:update, config) do
    Logger.info "Start polling #{config[:id]}"
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
    schedule_update config, config[:delay]
  end
  defp handle_load(config, :unchanged) do
    on_unchanged config
    schedule_update config, config[:delay]
  end
  defp handle_load(config, :error) do
    schedule_update config, config[:delay]
  end

  # If delay has been configured to 0, the update will be done only once.
  defp schedule_update(config, 0) do
    Logger.info "Stopping scheduled updates for #{config[:id]}"
  end
  defp schedule_update(_config, delay) do
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

  defp first_launch do
    case :ets.lookup ets_table, :first_launch do
      {:first_launch, false} ->
        false
      _ ->
        :ets.insert ets_table, {:first_launch, false}
        true
    end
  end

  defp ets_table do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    ets_table
  end

end
