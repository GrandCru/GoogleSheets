defmodule GoogleSheets do

  use Application
  require Logger

  @moduledoc """
  Main starting point of the application and public API for library.
  For introduction on how to configure and use the library, see [README](extra-readme.html).
  """

  @doc false
  def start(_type, _args) do
    GoogleSheets.Supervisor.start_link
  end

  #
  # Public client API
  #

  @doc ~S"""
  Fetches previously loaded spreadsheet data from ETS matching the given version and returns it as a {:ok, data} tuple.

  ## Examples

      iex> GoogleSheets.fetch "fccb56afd7d7f1cdf457e8b9b841ec75"
      {:ok, [
        %GoogleSheets.WorkSheet{
          csv: "Key,Value\r\nInteger,1\r\nFloat,1.1\r\nString,string",
          name: "KeyValue"
        }]
      }

      iex> GoogleSheets.fetch "not_a_valid_version"
      :not_found
  """
  @spec fetch(term) :: {:ok, term} | :not_found
  def fetch(version) do
    case :ets.lookup :google_sheets, version do
      [] -> :not_found
      [{^version, %{data: data}}] -> {:ok, data}
    end
  end

  @doc ~S"""
  Fetches previously loaded spreadsheet data from ETS matching the given version. KeyError is raised if no
  spreadsheet data is found with the given version.

  ## Examples

      iex> GoogleSheets.fetch! "fccb56afd7d7f1cdf457e8b9b841ec75"
      [%GoogleSheets.WorkSheet{
        csv: "Key,Value\r\nInteger,1\r\nFloat,1.1\r\nString,string",
        name: "KeyValue"}
      ]

      iex> GoogleSheets.fetch! "not_a_valid_version"
      ** (KeyError) key "not_a_valid_version" not found
  """
  @spec fetch!(term) :: term | no_return
  def fetch!(version) do
    case fetch version do
      :not_found -> raise KeyError, key: version
      {:ok, data} -> data
    end
  end

  @doc ~S"""
  Returns true, if there is a version stored for the spreadsheet identified by spreadsheet_id argument.
  """
  @spec has_version?(atom) :: boolean
  def has_version?(spreadsheet_id) when is_atom(spreadsheet_id) do
    case :ets.lookup :google_sheets, spreadsheet_id do
      [] -> false
      [{^spreadsheet_id, %{}}] -> true
    end
  end

  @doc ~S"""
  Returns {:ok, version, data} tuple for the latest stored version for the spreadsheet identified
  by spreadsheet_id argument. If there is no version available, :not_found is returned.
  """
  @spec latest(atom) :: {:ok, term, term} | :not_found
  def latest(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_version spreadsheet_id do
      :not_found ->
        :not_found
      {:ok, version} ->
        case :ets.lookup :google_sheets, version do
          [] ->
            :not_found
          [{^version, %{data: data}}] ->
            {:ok, version, data}
        end
    end
  end

  @doc ~S"""
  Returns {version, data} tuple for the latest stored version for the spreadsheet identified by
  spreadsheet_id argument. If no version is found, KeyError exception is raised.
  """
  @spec latest!(atom) :: {term, term} | no_return
  def latest!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest spreadsheet_id do
      :not_found -> raise KeyError, key: spreadsheet_id
      {:ok, version, data} -> {version, data}
    end
  end

  @doc ~S"""
  Returns {:ok, data} tuple for the latest stored entry for the spreadsheet identified by
  spreadsheet_id argument. If no entry is found, :not_found is returned.
  """
  @spec latest_data(atom) :: {:ok, term} | :not_found
  def latest_data(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest spreadsheet_id do
      :not_found -> :not_found
      {:ok, _version, data} -> {:ok, data}
    end
  end

  @doc ~S"""
  Returns the latest stored entry for the spreadsheet identified by spreadsheet_id argument. If
  no entry is found, KeyError exception is raised.
  """
  @spec latest_data!(atom) :: term | no_return
  def latest_data!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_data(spreadsheet_id) do
      {:ok, data} -> data
      :not_found -> raise KeyError, key: spreadsheet_id
    end
  end

  @doc ~S"""
  Returns {:ok, version} tuple or the latest stored version for the spreadsheet identified by
  spreadsheet_id argument. If no version is found, :not_found is returned.
  """
  @spec latest_version(atom) :: {:ok, term} | :not_found
  def latest_version(spreadsheet_id) when is_atom(spreadsheet_id) do
    case :ets.lookup :google_sheets, spreadsheet_id do
      [] ->
        :not_found
      [{^spreadsheet_id, %{version: version}}] ->
        {:ok, version}
    end
  end

  @doc ~S"""
  Returns the latest version stored for the spreadsheet identified by spreadsheet_id argument.
  If no version is found, KeyError exception is raised.
  """
  @spec latest_version!(atom) :: term | no_return
  def latest_version!(spreadsheet_id) when is_atom(spreadsheet_id) do
    case latest_version spreadsheet_id do
      :not_found -> raise KeyError, key: spreadsheet_id
      {:ok, version} -> version
    end
  end

  @doc ~S"""
  Manually triggers an update for fetching new data for the given spreadsheet_id argument.

  Return values:

  * {:updated, version}   - Spreadsheet was updated and stored with the version
  * :unchanged            - Spreadsheet contents haven't been changed since last update.
  * {:error, reason}      - The update failed because of reason.
  """
  @spec update(atom, integer) :: {:updated, term} | :unchanged | {:error, term} | no_return
  def update(spreadsheet_id, timeout \\ 60_000) do
    GoogleSheets.Updater.update spreadsheet_id, timeout
  end

end