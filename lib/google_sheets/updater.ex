defmodule GoogleSheets.Updater do

  @moduledoc """
  GenServer for updating and polling a spreadsheet.
  """

  use GenServer
  require Logger

  @default_poll_delay 5 * 60

  @doc false
  def update(spreadsheet_id, timeout) when is_atom(spreadsheet_id) do
    GenServer.call spreadsheet_id, :manual_update, timeout
  end

  @doc false
  def start_link(config) when is_list(config) do
    id = Keyword.fetch! config, :id
    GenServer.start_link(__MODULE__, config, [name: id])
  end

  @doc false
  def init(config) when is_list(config) do
    Logger.info "Starting updater process for spreadsheet #{inspect config[:id]}"

    # Don't load data from local filesystem if the updater process was restarted
    if not GoogleSheets.has_version? config[:id] do
      Logger.info "Loading initial data for spreadsheet #{inspect config[:id]} from #{inspect config[:dir]}"
      {:ok, loader_version, worksheets} = do_load GoogleSheets.Loader.FileSystem, config
      {:ok, parser_version, data} = do_parse parser_impl(config), config[:id], worksheets
      update_ets_entry config[:id], loader_version, parser_version, data
    end

    schedule_next_update config, Keyword.get(config, :poll_delay_seconds, @default_poll_delay)

    {:ok, config}
  end

  @doc false
  def handle_call(:manual_update, _from, config) do
    try do
      version = do_update config
      {:reply, {:ok, "Configuration updated succesfully, version is #{version}"}, config}
    catch
      {:ok, :unchanged} ->
        {:reply, {:ok, "No changes in configuration detected, configuration up-to-date."}, config}
      {:error, reason} ->
        {:reply, {:error, reason}, config}
    rescue
      exception ->
        stacktrace = System.stacktrace
        {:reply, {:error, "Exception while updating configuration.\n\nExcption:\n#{inspect exception}\n\nStacktrace\n#{inspect stacktrace}"}, config}
    end
  end

  @doc false
  def handle_info(:update, config) do
    try do
      do_update config
    catch
      {:ok, :unchanged} -> {:ok, :unchanged}
      {:error, reason} ->  {:error, reason}
    end
    schedule_next_update config, Keyword.get(config, :poll_delay_seconds, @default_poll_delay)
    {:noreply, config}
  end

  defp do_update(config) do
    {:ok, loader_version, worksheets} = do_load loader_impl(config), config
    {:ok, parser_version, data} = do_parse parser_impl(config), config[:id], worksheets
    update_ets_entry config[:id], loader_version, parser_version, data
  end

  defp do_load(impl, config) do
    case impl.load latest_loader_version(config[:id]), config do
      {:ok, version, worksheets} ->
        {:ok, version, worksheets}
      result ->
        throw result
    end
  end

  # If no parser is configured and raw CSV data is stored into ETS, calculate md5 hash,
  # otherwise call the module implementing parser behaviour
  defp do_parse(nil, _id, worksheets) when is_list(worksheets) do
    {:ok, calculate_hash(worksheets), worksheets}
  end
  defp do_parse(impl, id, worksheets) when is_list(worksheets) do
    case impl.parse id, worksheets do
      {:ok, version, data} ->
        {:ok, version, data}
      {:ok, data} ->
        {:ok, calculate_hash(data), data}
      result ->
        throw result
    end
  end

  # Write a new entry into ETS table and make the {:id, :latest} tuple point to new version
  defp update_ets_entry(id, loader_version, parser_version, data) do
    :ets.insert :google_sheets, {parser_version, loader_version, data, id}
    :ets.insert :google_sheets, {{id, :latest}, parser_version}
    parser_version
  end

  # If update_delay has been configured to 0, no updates will be done
  defp schedule_next_update(config, 0), do: Logger.info("Stopping scheduled updates for #{config[:id]}")
  defp schedule_next_update(_config, delay_seconds), do: Process.send_after(self, :update, delay_seconds * 1000)

  # Calculate md5 hash from any data, by converting to binary first if needed
  defp calculate_hash(binary) when is_binary(binary) do
    :crypto.hash(:md5, binary) |> Base.encode16(case: :lower)
  end
  defp calculate_hash(data) do
    calculate_hash :erlang.term_to_binary(data)
  end

  # Return the module implementing parser, if configured or nil
  defp parser_impl(config) do
    Keyword.get config, :parser
  end

  # Return the module implementing polling loader, default to GoogleSheets.Loader.Docs
  defp loader_impl(config) do
    Keyword.fetch! config, :loader
  end

  defp latest_loader_version(id) when is_atom(id) do
    case GoogleSheets.latest_version id do
      :not_found ->
        nil
      {:ok, version} ->
        [{^version, loader_version, _data, _id}] = :ets.lookup :google_sheets, version
        loader_version
    end
  end

end
