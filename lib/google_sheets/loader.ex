defmodule GoogleSheets.Loader do

  @moduledoc """
  Modules implementing this behavior load CSV data from a source and return a list of WorkSheet structures containing
  raw CSV data for each worksheet given in config argument.
  """

  @doc """
  Loads spreadsheet data from configured source.

  Arguments:

  * version - Version value returned by a previous call to any loader or nil.
  * id - ID of the spreadsheet to be loaded
  * config - Configuration options specified in application configuration for the spreadsheet.

  Return values:

  * {:ok, version, worksheets} - Tuple with version value to be used during next update or nil and list of WorkSheet structures containing CSV data.
  * {:ok, :unchanged} - No changes in spreadsheet data.
  * {:error, reason} - Known and handled error case, which can be potentially corrected. (Network errors etc.)
  """
  @callback load(version :: String.t | nil, id :: atom, config :: Keyword.t) :: {:ok, version :: binary, [GoogleSheets.WorkSheet.t]} | :unchanged | {:error, reason :: String.t}
end
