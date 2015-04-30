defmodule GoogleSheets.Updater do

  @moduledoc """
  GenServer for updating and polling a spreadsheet.
  """

  use GenServer
  require Logger
  alias GoogleSheets.Utils

  #
  # Client API
  #
  def update_config(spreadsheet_id, timeout \\ 60_000) when is_atom(spreadsheet_id) do
    GenServer.call spreadsheet_id, :update_config, timeout
  end

  #
  # Implementation
  #

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, [name: config[:id]])
  end

  # Initial update
  def init(config) do
    Logger.info "Starting updater process for spreadsheet #{config[:id]}"

    # Don't use loader_init except during the very first launch
    if nil == latest_version config[:id] do
      result = load_spreadsheet config, Keyword.fetch!(config, :loader_init)
      update_ets_entry result, config
    end

    schedule_next_update config, Keyword.fetch!(config, :poll_delay_seconds)
    {:ok, config}
  end

  # Handle manual update request, don't crash here so that we can return a error information and show it to user
  def handle_call(:update_config, _from, config) do
    try do
      result = load_spreadsheet config, Keyword.fetch!(config, :loader_poll)
      status = update_ets_entry result, config
      {:reply, {:ok, status}, config}
    rescue
      error -> {:reply, {:error, error}, config}
    end
  end

  # Polling update
  def handle_info(:update, config) do
    result = load_spreadsheet config, Keyword.fetch!(config, :loader_poll)
    update_ets_entry result, config
    schedule_next_update config, Keyword.fetch!(config, :poll_delay_seconds)
    {:noreply, config}
  end

  # Load spreadsheet data with a configured loader
  defp load_spreadsheet(config, loader_config) do
    sheets = Keyword.fetch! config, :sheets
    module = Keyword.fetch! loader_config, :module
    module.load sheets, latest_version(config[:id]), loader_config
  end

  # Update ets table or notify that the data loaded was unchanged
  defp update_ets_entry(:error, config) do
    Logger.info "Failed loading data for #{config[:id]}"
    :error
  end
  defp update_ets_entry(:unchanged, config) do
    Logger.debug "No changes in #{config[:id]}"
    on_unchanged(Keyword.fetch!(config, :callback_module), Keyword.fetch!(config, :id))
    :unchanged
  end
  defp update_ets_entry({version, spreadsheet}, config) do
    id = Keyword.fetch! config, :id
    key = UUID.uuid1
    callback_module = Keyword.fetch! config, :callback_module

    Logger.info "Updating spredsheet: #{inspect id} version: #{inspect version} key: #{inspect key}"

    data = on_loaded callback_module, id, spreadsheet

    :ets.insert Utils.ets_table, {{id, key}, data}
    :ets.insert Utils.ets_table, {{id, :latest}, version, key}

    on_saved callback_module, id, data
    :updated
  end

  # If update_delay has been configured to 0, no updates will be done
  defp schedule_next_update(config, 0) do
    Logger.info "Stopping scheduled updates for #{config[:id]}"
  end
  defp schedule_next_update(config, delay_seconds) do
    Logger.debug "Scheduling next update for #{config[:id]} in #{delay_seconds} seconds"
    Process.send_after self, :update, delay_seconds * 1000
  end

  #
  # Callbacks if defined on configuration
  #
  defp on_loaded(nil, _id, spreadsheet), do: spreadsheet
  defp on_loaded(module, id, spreadsheet), do: module.on_loaded(id, spreadsheet)

  defp on_saved(nil, _id, data), do: data
  defp on_saved(module, id, data), do: module.on_saved(id, data)

  defp on_unchanged(nil, _id), do: nil
  defp on_unchanged(module, id), do: module.on_unchanged id

  #
  # Helpers
  #
  defp latest_version(id) when is_atom(id) do
    case :ets.lookup Utils.ets_table, {id, :latest} do
      [{_lookup_key, version, _key}] ->
        version
      _ ->
        nil
    end
  end

end
