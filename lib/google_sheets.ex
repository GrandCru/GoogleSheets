
defmodule GoogleSheets do

  use Application
  require Logger

  @moduledoc """
  Main starting point of the application and provides functions defining the public client API for the library.
  """

  @doc false
  def start(_type, _args) do
    GoogleSheets.Supervisor.start_link
  end

  #
  # Public client API
  #

  @doc ~S"""
  Returns {:ok, version_key} where version_key is the one for latest version stored in ETS table.

  If no entry is found, :not_found is returned.
  """
  def latest_key(spreadsheet_id) when is_atom(spreadsheet_id) do
    ets_table = Application.get_env :google_sheets, :ets_table, :google_sheets
    case :ets.lookup ets_table, {spreadsheet_id, :latest} do
      [] -> :not_found
      [{{^spreadsheet_id, :latest}, key}] -> {:ok, key}
    end
  end

  @doc ~S"""
  Returns version_key where version_key is the one for latest version stored in ETS table.

  If no entry is found, an KeyError exception is raised.
  """
  def latest_key!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_key spreadsheet_id do
      :not_found -> raise KeyError, key: spreadsheet_id
      key -> key
    end
  end

  @doc ~S"""
  Returns {:ok, version_key, data} tuple matching an entry in ETS table for the passed spreadsheet_id, version_key pair.

  If no version_key is given, the latest stored version is returned.

  If no entry is found, :not_found is returned.
  """
  def fetch(spreadsheet_id, version_key \\ :latest) when is_atom(spreadsheet_id) do
    if version_key == :latest do
      case latest_key spreadsheet_id do
        :not_found -> :not_found
        key -> version_key = key
      end
    end

    ets_table = Application.get_env :google_sheets, :ets_table, :google_sheets
    case :ets.lookup ets_table, {spreadsheet_id, version_key} do
      [] -> :not_found
      [{{^spreadsheet_id, ^version_key}, data}] -> {:ok, version_key, data}
    end
  end

  @doc ~S"""
  Return {version_key, data} tuple matching an entry in ETS table for the passed spreadsheet_id, version_key pair.

  If no version_key is given, the latest stored version is returned.

  If no entry is found, an KeyError exception is raised.
  """
  def fetch!(spreadsheet_id, version_key \\ :latest) when is_atom(spreadsheet_id) do
    case fetch spreadsheet_id, version_key do
      :not_found -> raise KeyError, key: {spreadsheet_id, version_key}
      {:ok, version_key, data} -> {version_key, data}
    end
  end

  @doc ~S"""
  Requests the updater process monitoring the given spreadsheet to check for changes immediately.

  Return values:
  {:updated, version_key} - Spreadsheet was updated and stored with the version_key
  :unchanged              - Spreadsheet contents haven't been changed since last update.
  {:error, reason}        - The update failed because of reason.
  """
  def update(spreadsheet_id, timeout \\ 60_000) do
    GoogleSheets.Updater.update spreadsheet_id, timeout
  end

end