defmodule GoogleSheets.Loader do

  use Behaviour

  @moduledoc """
  Behaviour for a spreadsheet loader.

  Each module implementing this behaviour is expected to load CSV data from a source and return unique version identifier and list of WorkSheet.t structures.
  """

  @doc """
  The load callback can be called by and updater process or by any other process wishing to load data.

  Versioning:

  Each loader implementation can implement a method to short circuiting loading CSV data. For example, the docs.ex loader calculates a
  hash from the atom feed url, it's last update entry and given list of sheet names. If the data read from the atom feed matches, it can
  return {:ok, unchanged} without loading CSV data for all sheets.

  The parameters:

  * version - Version value returned by a previous call to a loader.
  * config  - Loader specific configuration.

  Return values:

  * {:ok, version, spreadsheet} - SpreadSheetData structure containing unparsed CSV data, version i
  * {:ok, :unchanged}   - No changes since last load time in spreadsheet.
  * {:error, reason}    - An handled error case during loading of data.

  """
  defcallback load(version :: String.t | nil, config :: Keyword.t) :: {:ok, version :: binary, [GoogleSheets.WorkSheet.t]} | :unchanged | {:error, reason :: String.t}
end
