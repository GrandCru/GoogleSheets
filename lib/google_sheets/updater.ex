defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  def start_link(%GoogleSheets.Updater.Config{} = config, options \\ []) do
    GenServer.start_link(__MODULE__, config, options)
  end

  def init(%GoogleSheets.Updater.Config{} = config) do
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
    case GoogleSheets.Loader.load config.key, config.sheets do
      {:ok, data} ->
        data = on_loaded config, data
        :ets.insert config.ets_table, {config.ets_key, data}
        on_saved config
        schedule_update config.delay
      {:error, msg} ->
        # Schedule an update again immediately if the request failed.
        # Note: This means we will keep trying to fetch data at least once, even if delay is 0
        Logger.debug "Failed to load data from google sheets, scheduling update immediately. Reason: #{inspect msg}"
        schedule_update 1
    end
  end

  # If delay has been configured to 0, the update will be done only once.
  defp schedule_update(0) do
    Logger.debug "Stopping scheduled updates"
  end
  defp schedule_update(delay) do
    Logger.debug "Next update in #{delay} seconds"
    Process.send_after self(), :update, delay * 1000
  end

  def on_loaded(%GoogleSheets.Updater.Config{:callback => nil}, data), do: data
  def on_loaded(%GoogleSheets.Updater.Config{} = config, data), do: config.callback.on_loaded data

  def on_saved(%GoogleSheets.Updater.Config{:callback => nil}), do: nil
  def on_saved(%GoogleSheets.Updater.Config{} = config), do: config.callback.on_saved

end
