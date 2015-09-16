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
  Returns {:ok, data} tuple for the spreadsheet stored in the ETS table with given key.

  :not_found is returned, if no data is found in ETS table for the given version.
  """
  def fetch(version) do
    case :ets.lookup :google_sheets, version_key do
      [] -> :not_found
      [{^version_key, _loader_version, data}] -> {:ok, data}
    end
  end

  @doc ~S"""
  Returns spreadsheet data stored in ETS table with the given key.

  KeyError is raised if no data is found with the given version.
  """
  def fetch!(version) do
    case fetch version do
      :not_found -> raise KeyError, key: version
      {:ok, data} -> data
    end
  end

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
  Returns {:ok, version, data} for the latest spreadsheet update stored in ETS.

  :not_found is returned if no entry if found in ETS.
  """
  def latest(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_version spreadsheet_id do
      :not_found -> :not_found
      {:ok, version} ->
        case fetch version do
          :not_found -> :not_found
          {:ok, data} -> {:ok, version, data}
        end
    end
  end

  @doc ~S"""
  Returns {version, data} for the latest spreadsheet update stored in ETS.

  If no entry is found, an KeyError exception is raised.
  """
  def latest!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest spreadsheet_id do
      :not_found -> raise KeyError, key: spreadsheet_id
      {:ok, version_key, data} -> {version_key, data}
    end
  end

  @doc ~S"""
  Returns {:ok, version} tuple, where version points to latest stored version in ETS.

  :not_found is returned, if no stored version is found in ETS.
  """
  def latest_version(spreadsheet_id) when is_atom(spreadsheet_id) do
    case :ets.lookup :google_sheets, {spreadsheet_id, :latest} do
      [] ->
        :not_found
      [{{^spreadsheet_id, :latest}, version}] ->
        {:ok, version}
    end
  end

  @doc ~S"""
  Returns latest version stored for the given spreadsheet in ETS.

  KeyError exception is raised if no version is found in ETS.
  """
  def latest_version!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_version spreadsheet_id do
      :not_found -> raise KeyError, key: spreadsheet_id
      {:ok, version} -> version
    end
  end

  @doc ~S"""
  Returns {:ok, data} for the latest spreadsheet update stored in ETS.

  If no entry is found, :not_found is returned.
  """
  def latest_data(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest spreadsheet_id do
      :not_found -> :not_found
      {:ok, _version_key, data} -> {:ok, data}
    end
  end

  @doc ~S"""
  Returns data where data is the latest one found.

  If no entry is found, an KeyError exception is raised.
  """
  def latest_data!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_data(spreadsheet_id) do
      {:ok, data} -> data
      :not_found -> raise KeyError, key: spreadsheet_id
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