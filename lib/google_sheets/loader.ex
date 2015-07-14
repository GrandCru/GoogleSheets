defmodule GoogleSheets.Loader do

  use Behaviour

  @moduledoc """
  Behaviour for a spreadsheet loader.

  Each module implementing this behaviour is expected to load CSV data from a source and return unique version identifier and list of WorkSheet.t structures.
  """

  @doc """
  The load callback can be called by and updater process or by any other process wishing to load data.

  Versioning:

  Each loader implementation must implement a way to uniquely identify loaded CSV data. For example, the docs.ex loader calculates
  an hash from the atom feed last updated data and URL. The file_system.ex loaded calculates an hash from the combined CSV data.

  The version value is used as part of the key for looking up a specific version of a configuration from the ETS table. To support
  multinode architectures, the same raw CSV data should always result in equal hash.

  Another purpose of this is to allow a mechanism for doing quicker check on data changes. For example, the docs.ex loader doesn't
  actually have to fetch all spreadsheets since it can deduce whether the data has changed or not based on the calculated hash value.

  The parameters:

  * previous_version  - Version value returned by a previous call to a loader.
  * config            - Configuration for the loaded. The updater passes the whole config of the spreadsheet as value.
                        Expected to by a keyword list.

  Return values:

  * {:ok, spreadsheet}  - SpreadSheetData structure. The version parameter is equal to source URL
  * {:ok, :unchanged}   - No changes since last load time in spreadsheet.
  * {:error, reason}    - An handled error case during loading of data.

  """
  defcallback load(previous_identifier :: String.t | nil, config :: Keyword.t) :: {:ok, version :: binary, [GoogleSheets.WorkSheet.t]} | :unchanged | {:error, reason :: String.t}
end
