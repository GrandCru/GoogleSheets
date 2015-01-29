defmodule GoogleSheets.Updater do

  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    key = Application.get_env :google_sheets, :key, nil
    interval = Application.get_env :google_sheets, :update_interval_ms, 0

    case key do
      nil -> Logger.info "#{__MODULE__} not starting polling updates, because key was not set in :google_sheets configuration"
      _ -> Process.send_after self(), :update, 0
    end

    {:ok, {key, interval}}
  end

  def handle_info(:update, {key, poll_interval}) do
    handle_update key, poll_interval
    {:noreply, {key, poll_interval}}
  end

  # Internal implemantation
  def handle_update(key, poll_interval) do
    case GoogleSheets.Loader.load key do
      {:ok, data} ->
        Logger.debug "Loaded new configuration from google"
        :ets.insert :google_sheets, {:data, data}
        schedule_update poll_interval
      {:error, msg} ->
        # Schedule again immediately, even if poll_interval is 0, if the first load failed
        Logger.debug "Failed to load data from google sheets, scheduling update immediately. Reason: #{inspect msg}"
        schedule_update 1
    end
  end

  defp schedule_update(0), do: nil
  defp schedule_update(poll_interval), do: Process.send_after(self(), :update, poll_interval)
end