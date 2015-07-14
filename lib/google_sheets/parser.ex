defmodule GoogleSheets.Parser do
  use Behaviour

  @moduledoc """
  Behaviour for parsing and transforming loaded CSV data into application specific format before
  it's stored into ETS table.
  """

  @doc """
  After udpater process has loaded CSV data, but before data is stored into ETS table an application can parse the
  raw data by writing a module implementing this behaviour.

  To configure this method, use the :parser configure setting for a spreadsheet. If no :parser is configured or it is
  set to nil, the updater process will store the list of Worksheet entires into ETS table.

  Parameters:

  * spreadsheet_id  - The configured :id parameter for a monitored spreadsheet
  * worksheets      - List of Worksheet structures.

  Return values:

  * {:ok, data}       - In case data was succesfully parased, the data can be anything that can be stored into ETS table
  * {:error, reason}  - If parsing failed for a known reason.
  """
  defcallback parse(spreadsheet_id :: atom, worksheets :: [GoogleSheets.WorkSheet.t]) :: {:ok, any} | {:error, reason :: binary}

end
