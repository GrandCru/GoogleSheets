defmodule GoogleSheets.Updater do

  @moduledoc """
  GenServer for updating and polling a spreadsheet.
  """

  use GenServer
  require Logger

  @default_poll_delay 5 * 60

  @doc false
  def update(spreadsheet_id, timeout) when is_atom(spreadsheet_id) do
    GenServer.call spreadsheet_id, :update_config, timeout
  end

  @doc false
  def start_link(config) when is_list(config) do
    id = Keyword.fetch! config, :id
    GenServer.start_link(__MODULE__, config, [name: id])
  end

  @doc false
  def init(config) when is_list(config) do
    Logger.info "Starting updater process for spreadsheet #{inspect config[:id]}"

    # Don't load data from local filesystem if the updater process has been restarted
    if :not_found == GoogleSheets.latest_key config[:id] do
      Logger.info "Loading initial data for spreadsheet #{inspect config[:id]} from #{inspect config[:dir]}"
      {:ok, version, worksheets} = GoogleSheets.Loader.FileSystem.load nil, config
      {:ok, data} = parse Keyword.get(config, :parser), config[:id], worksheets
      update_ets_entry config[:id], version, data
    end

    schedule_next_update config, Keyword.get(config, :poll_delay_seconds, @default_poll_delay)

    {:ok, config}
  end

  @doc false
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
        stacktrace = System.stacktrace
        {:reply, {:error, "Exception while updating configuration.\n\nExcption:\n#{inspect exception}\n\nStacktrace\n#{inspect stacktrace}"}, config}
    end
  end

  @doc false
  def handle_info(:update, config) do
    do_update config
    schedule_next_update config, Keyword.get(config, :poll_delay_seconds, @default_poll_delay)
    {:noreply, config}
  end

  defp do_update(config) do
    try do
      {version, worksheets} = load_spreadsheet config
      data = parse_spreadsheet worksheets, config
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

  defp parse_spreadsheet(worksheets, config) do
    case parse Keyword.get(config, :parser), config[:id], worksheets do
      {:ok, data} -> data
      result -> throw result
    end
  end

  defp update_ets_entry(id, version, data) do
    :ets.insert :google_sheets, {{id, version}, data}
    :ets.insert :google_sheets, {{id, :latest}, version}
    {:ok, version}
  end

  # If update_delay has been configured to 0, no updates will be done
  defp schedule_next_update(config, 0), do: Logger.info("Stopping scheduled updates for #{config[:id]}")
  defp schedule_next_update(_config, delay_seconds), do: Process.send_after(self, :update, delay_seconds * 1000)

  # Parse CSV data if configured to do so
  defp parse(nil, _id, worksheets) when is_list(worksheets), do: {:ok, worksheets}
  defp parse(module, id, worksheets) when is_list(worksheets), do: module.parse(id, worksheets)
end
