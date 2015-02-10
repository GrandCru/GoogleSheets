defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    {:ok, key} = Application.fetch_env :google_sheets, :key
    {:ok, sheets} = Application.fetch_env :google_sheets, :sheets
    {:ok, delay} = Application.fetch_env :google_sheets, :delay
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    {:ok, ets_key} = Application.fetch_env :google_sheets, :ets_key
    state = %{key: key, sheets: sheets, delay: delay, ets_table: ets_table, ets_key: ets_key}

    # Send the first poll request immediately
    Process.send_after self(), :update, 0

    {:ok, state}
  end

  def handle_info(:update, state) do
    handle_update state
    {:noreply, state}
  end

  # Internal implementation
  defp handle_update(state) do
    case GoogleSheets.Loader.load state.key, state.sheets do
      {:ok, data} ->
        Logger.debug "Loaded new configuration from google"
        :ets.insert state.ets_table, {state.ets_key, data}
        schedule_update state.delay * 1000
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

end