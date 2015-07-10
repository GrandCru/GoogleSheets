defmodule GoogleSheets.Callback do
  use Behaviour

  @moduledoc """
  Behaviour for callbacks transforming SpreadSheetData structure into application specific format.
  """

  @doc """
  Called when a new version of a spreadsheet has been loaded, but before it has been saved to ETS.

  The main reason for this callback is to transform the raw CSV data into application specific format.
  For example, you could use ex_csv library to convert the data into a map and return that as the data
  to store into ETS table.

  The data returned can be of any type that can be inserted into ETS table.
  """
  defcallback on_loaded(spreadsheet_id :: atom, data :: GoogleSheets.SpreadSheetData.t) :: {:ok, any} | :unchanged | :error

end
