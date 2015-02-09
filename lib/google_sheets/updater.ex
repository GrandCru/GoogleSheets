defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    {:ok, key} = Application.fetch_env :google_sheets, :key
    {:ok, delay} = Application.fetch_env :google_sheets, :delay
    {:ok, sheets} = Application.fetch_env :google_sheets, :sheets
    Process.send_after self(), :update, 0
    {:ok, {key, delay, sheets}}
  end

  def handle_info(:update, {key, poll_interval, sheets}) do
    handle_update key, poll_interval, sheets
    {:noreply, {key, poll_interval}}
  end

  # Internal implemantation
  defp handle_update(key, delay, sheets) do
    case GoogleSheets.Loader.load key, sheets do
      {:ok, data} ->
        Logger.debug "Loaded new configuration from google"
        :ets.insert :google_sheets, {:data, data}
        schedule_update delay * 1000
      {:error, msg} ->
        # Schedule an update again immediately if the request failed.
        # Note: This means we will keep trying to fetch data at least once, even if dealy is 0
        Logger.debug "Failed to load data from google sheets, scheduling update immediately. Reason: #{inspect msg}"
        schedule_update 1
    end
  end

  # When to poll next time, if delay has been configured to 0, the update will be done only once.
  defp schedule_update(0), do: nil
  defp schedule_update(delay), do: Process.send_after(self(), :update, delay * 1000)
end