defmodule GoogleSheets.Callback do
  use Behaviour

  @moduledoc """
  Behaviour for callbacks when updated has loaded a spreadsheet.
  """

  @doc """
  Called by the updater process when loader returns :unchanged result.
  """
  defcallback on_unchanged(spreadsheet_id :: atom) :: any

  @doc """
  Called when a new version of a spreadsheet has been loaded, but before it has been saved to ETS.

  The main reason for this callback is to transform the raw CSV data into application specific format.
  For example, you could use ex_csv library to convert the data into a map and return that as the data
  to store into ETS table.

  The data returned can be of any type that can be inserted into ETS table.
  """
  defcallback on_loaded(spreadsheet_id :: atom, data :: GoogleSheets.SpreadSheetData.t) :: {:ok, any} | :unchanged | :error

  @doc """
  Called after the data has been persisted to ETS.

  The data passed to this function is equal to return value of on_loaded callback.
  """
  defcallback on_saved(spreadsheet_id :: atom, data :: any) :: any

end
