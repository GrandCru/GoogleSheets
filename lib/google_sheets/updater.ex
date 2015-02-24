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
        Logger.debug "Loaded new configuration from google"
        data = transform config, data
        notify config, data
        :ets.insert config.ets_table, {config.ets_key, data}
        schedule_update config.delay * 1000
      {:error, msg} ->
        # Schedule an update again immediately if the request failed.
        # Note: This means we will keep trying to fetch data at least once, even if dealy is 0
        Logger.debug "Failed to load data from google sheets, scheduling update immediately. Reason: #{inspect msg}"
        schedule_update 1
    end
  end

  # If delay has been configured to 0, the update will be done only once.
  defp schedule_update(0), do: nil
  defp schedule_update(delay), do: Process.send_after(self(), :update, delay * 1000)

  defp transform(config, data) do
    if config.transform != nil do
      config.transform.do_transform data
    end
  end

  defp notify(config, data) do
    if config.notify != nil do
      config.notify.on_update data
    end
  end

end
