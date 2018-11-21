defmodule GoogleSheets.Updater do
  @moduledoc """
  GenServer for updating and polling a spreadsheet.
  """

  use GenServer
  require Logger

  defmodule State do
    defstruct id: nil, config: nil
  end

  @default_poll_delay 5 * 60

  @doc false
  def start_link(id, config) when is_atom(id) and is_list(config) do
    GenServer.start_link(__MODULE__, %State{id: id, config: config}, name: id)
  end

  @doc false
  @spec update(spreadsheet_id :: atom, timeout :: non_neg_integer) ::
          {:ok, :updated, String.t()} | {:ok, :unchanged} | {:error, term}
  def update(spreadsheet_id, timeout)
      when is_atom(spreadsheet_id) and is_integer(timeout) and timeout >= 0 do
    GenServer.call(spreadsheet_id, :manual_update, timeout)
  end

  @doc false
  def init(%State{} = state) do
    Logger.info(
      "Starting updater process for spreadsheet #{state.id} with config #{inspect(state.config)}"
    )

    load_initial_version(state, GoogleSheets.has_version?(state.id))

    schedule_next_update(
      state.id,
      Keyword.get(state.config, :poll_delay_seconds, @default_poll_delay)
    )

    {:ok, state}
  end

  defp load_initial_version(%State{}, true) do
    :ok
  end

  defp load_initial_version(%State{} = state, false) do
    Logger.info(
      "Loading initial data for spreadsheet #{state.id} from filesystem directory: #{
        inspect(state.config[:dir])
      }"
    )

    {:ok, loader_version, worksheets} = do_load(GoogleSheets.Loader.FileSystem, state)
    {:ok, version, data} = do_parse(parser_impl(state), state.id, worksheets)
    update_ets_entry(state.id, version, loader_version, data)
    Logger.info("Initial data for spreadsheet #{state.id} loaded, version is now #{version}")
  end

  @doc false
  def handle_call(:manual_update, _from, %State{} = state) do
    Logger.info("Doing requested manual update for spreadsheet #{state.id}")

    try do
      version = do_update(state)
      {:reply, {:ok, :updated, version}, state}
    catch
      {:ok, :unchanged} ->
        {:reply, {:ok, :unchanged}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    rescue
      exception ->
        stacktrace = System.stacktrace()

        {:reply,
         {:error,
          "Exception while updating configuration.\n\nExcption:\n#{inspect(exception)}\n\nStacktrace\n#{
            inspect(stacktrace)
          }"}, state}
    end
  end

  @doc false
  def handle_info(:update, %State{} = state) do
    try do
      do_update(state)
    catch
      {:ok, :unchanged} ->
        :ok

      {:error, reason} ->
        Logger.error("Error updating spreadsheet #{state.id} #{inspect(reason)}")
    end

    schedule_next_update(
      state.id,
      Keyword.get(state.config, :poll_delay_seconds, @default_poll_delay)
    )

    {:noreply, state}
  end

  defp do_update(%State{} = state) do
    {:ok, loader_version, worksheets} = do_load(loader_impl(state), state)
    {:ok, version, data} = do_parse(parser_impl(state), state.id, worksheets)

    if version == GoogleSheets.latest_version(state.id) do
      throw({:ok, :unchanged})
    end

    update_ets_entry(state.id, version, loader_version, data)
  end

  defp do_load(impl, %State{} = state) do
    previous_version = latest_loader_version(state.id)

    case impl.load(previous_version, state.id, state.config) do
      {:ok, version, worksheets} ->
        {:ok, version, worksheets}

      result ->
        throw(result)
    end
  end

  # If no parser is configured and raw CSV data is stored into ETS, calculate MD5 hash,
  # otherwise call the module implementing parser behavior
  defp do_parse(nil, _id, worksheets) when is_list(worksheets) do
    worksheets =
      Enum.sort(worksheets, fn %GoogleSheets.WorkSheet{} = a, %GoogleSheets.WorkSheet{} = b ->
        a.name < b.name
      end)

    {:ok, calculate_hash(worksheets), worksheets}
  end

  defp do_parse(impl, id, worksheets) when is_list(worksheets) do
    case impl.parse(id, worksheets) do
      {:ok, version, data} ->
        {:ok, version, data}

      {:ok, data} ->
        {:ok, calculate_hash(data), data}

      result ->
        throw(result)
    end
  end

  # Write a new entry into ETS table and make the {:id, :latest} tuple point to new version
  defp update_ets_entry(id, version, loader_version, data) do
    Logger.info(
      "Updating ETS entry for spreadsheet #{id} version #{inspect(version)} loader_version #{
        inspect(loader_version)
      }"
    )

    :ets.insert(
      :google_sheets,
      {version, %{id: id, version: version, loader_version: loader_version, data: data}}
    )

    :ets.insert(:google_sheets, {id, %{version: version}})
  end

  # If update_delay has been configured to 0, no updates will be done
  defp schedule_next_update(id, 0), do: Logger.info("Stopping updates for #{id}")

  defp schedule_next_update(_id, delay_seconds),
    do: Process.send_after(self(), :update, delay_seconds * 1000)

  # Calculate MD5 hash from any data, by converting to binary first if needed
  defp calculate_hash(binary) when is_binary(binary) do
    :crypto.hash(:md5, binary) |> Base.encode16(case: :lower)
  end

  defp calculate_hash(data) do
    calculate_hash(:erlang.term_to_binary(data))
  end

  # Returns the module implementing parser or nil if not configured
  defp parser_impl(%State{config: config}) do
    Keyword.get(config, :parser)
  end

  # Returns the module implementing polling loader
  defp loader_impl(%State{config: config}) do
    Keyword.get(config, :loader, GoogleSheets.Loader.Docs)
  end

  defp latest_loader_version(id) when is_atom(id) do
    case GoogleSheets.latest_version(id) do
      :not_found ->
        nil

      {:ok, version} ->
        [{^version, %{loader_version: loader_version}}] = :ets.lookup(:google_sheets, version)
        loader_version
    end
  end
end
