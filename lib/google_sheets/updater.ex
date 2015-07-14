defmodule GoogleSheets.Updater do

  @moduledoc """
  GenServer for updating and polling a spreadsheet.
  """

  use GenServer
  require Logger

  @default_poll_delay 5 * 60

  #
  # Client API
  #
  def update(spreadsheet_id, timeout) when is_atom(spreadsheet_id) do
    GenServer.call spreadsheet_id, :update_config, timeout
  end

  #
  # Implementation
  #

  def start_link(config) when is_list(config) do
    id = Keyword.fetch! config, :id
    GenServer.start_link(__MODULE__, config, [name: id])
  end

  # Initial update
  def init(config) when is_list(config) do
    Logger.info "Starting updater process for spreadsheet #{config[:id]}"

    # Don't load data from local filesystem if the updater process has been restarted
    if :not_found == GoogleSheets.latest_key config[:id] do
      {:ok, version, worksheets} = GoogleSheets.Loader.FileSystem.load nil, config
      data = on_loaded_callback Keyword.get(config, :callback), config[:id], worksheets
      update_ets_entry config[:id], version, data
    end

    schedule_next_update config, Keyword.get(config, :poll_delay_seconds, @default_poll_delay)

    {:ok, config}
  end

  # Manual update request, rescue exceptions so that we can reply with result of the update.
  def handle_call(:update_config, _from, config) do
    try do
      case do_update config do
        {:ok, :unchanged} ->
          {:reply, {:ok, "No changes in configuration detected, configuration up-to-date."}, config}
        {:ok, version} ->
          {:reply, {:ok, "Configuration updated succesfully, version is #{version}."}, config}
        {:error, reason} ->
          {:reply, {:error, reason}, config}
      end
    rescue
      exception ->
        {:reply, {:error, "Exception while updating configuration.\n\nExcption:\n#{inspect exception}\n\nStacktrace\n#{inspect :erlang.get_stacktrace}"}, config}
    end
  end

  # Polling update request
  def handle_info(:update, config) do
    do_update config
    schedule_next_update config, Keyword.get(config, :poll_delay_seconds, @default_poll_delay)
    {:noreply, config}
  end

  defp do_update(config) do
    try do
      {version, worksheets} = load_spreadsheet config
      data = on_loaded_callback Keyword.get(config, :callback), config[:id], worksheets
      update_ets_entry config[:id], version, data
    catch
      result -> result
    end
  end

  defp load_spreadsheet(config) do
    loader = Keyword.get config, :loader, GoogleSheets.Loader.Docs
    case loader.load GoogleSheets.latest_key(config[:id]), config do
      {:ok, version, worksheets} -> {version, worksheets}
      result -> throw result
    end
  end

  defp update_ets_entry(id, version, data) do
    ets_table = Application.get_env :google_sheets, :ets_table, :google_sheets
    :ets.insert ets_table, {{id, version}, data}
    :ets.insert ets_table, {{id, :latest}, version}
    {:ok, version}
  end

  # If update_delay has been configured to 0, no updates will be done
  defp schedule_next_update(config, 0), do: Logger.info("Stopping scheduled updates for #{config[:id]}")
  defp schedule_next_update(_config, delay_seconds), do: Process.send_after(self, :update, delay_seconds * 1000)

  # Callbacks if defined on configuration
  defp on_loaded_callback(nil, _id, worksheets) when is_list(worksheets), do: worksheets
  defp on_loaded_callback(module, id, worksheets) when is_list(worksheets), do: module.on_loaded(id, worksheets)
end
