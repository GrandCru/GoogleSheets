
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
  Returns true, if there is an version for for the given spreadsheet_id stored, false otherwise.
  """
  def has_version?(spreadsheet_id) when is_atom(spreadsheet_id) do
    case :ets.lookup :google_sheets, {spreadsheet_id, :latest} do
      [] -> false
       _ -> true
    end
  end

  @doc ~S"""
  Returns {:ok, version_key, data} where version_key and data are the latest ones found.

  If no entry is found, :not_found is returned.
  """
  def latest(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_key spreadsheet_id do
      :not_found ->
        :not_found
      {:ok, version_key} ->
        case fetch version_key do
          :not_found ->
            Logger.error "No data found for spreadsheet_id #{inspect spreadsheet_id} version #{inspect version_key}"
            :not_found
          {:ok, data} ->
            {:ok, version_key, data}
        end
    end
  end

  @doc ~S"""
  Returns {version_key, data} for the latest one stored in ETS table.

  If no entry is found, an KeyError exception is raised.
  """
  def latest!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest spreadsheet_id do
      :not_found -> raise KeyError, key: spreadsheet_id
      {:ok, version_key, data} -> {version_key, data}
    end
  end

  @doc ~S"""
  Returns {:ok, version_key} where version_key is the one for latest version stored in ETS table.

  If no entry is found, :not_found is returned.
  """
  def latest_key(spreadsheet_id) when is_atom(spreadsheet_id) do
    case :ets.lookup :google_sheets, {spreadsheet_id, :latest} do
      [] ->
        Logger.error "No version key found for spreadsheet_id #{inspect spreadsheet_id}"
        :not_found
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
      {:ok, key} -> key
    end
  end

  @doc ~S"""
  Returns {:ok, version_key, data} tuple matching an entry in ETS table for the passed spreadsheet_id, version_key pair.

  If no version_key is given, the latest stored version is returned.

  If no entry is found, :not_found is returned.
  """
  def fetch(version_key) do
    case :ets.lookup  :google_sheets, version_key do
      [] -> :not_found
      [{^version_key, data}] -> {:ok, data}
    end
  end

  @doc ~S"""
  Returns data stored for the given version_key. If no entry is found, an KeyError exception is raised.
  """
  def fetch!(version_key) do
    case fetch version_key do
      :not_found -> raise KeyError, key: version_key
      {:ok, data} -> data
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