defmodule GoogleSheets.Loader do

  use Behaviour

  @moduledoc """
  Behaviour for a spreadsheet loader.

  Each module implementing this behaviour is expected to load CSV data from a source and return SpreadSheetData.t structure.
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
  defcallback load(previous_identifier :: String.t | nil, config :: Keyword.t) :: {identifier :: binary, spreadsheet :: GoogleSheets.SpreadSheetData.t} | :unchanged | {:error, reason :: String.t}
end

defmodule GoogleSheets.SpreadSheetData do
  @moduledoc """
  Structure containg a spreadsheet data in CSV format.

  Fields:

  * :version  - Uniquely identifying version
  * :sheets   - List of WorkSheetData structures.
  """

  @type t :: %GoogleSheets.SpreadSheetData{version: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
  defstruct version: nil, sheets: []

  def new(version, sheets) when is_list(sheets) do
    %GoogleSheets.SpreadSheetData{version: version, sheets: sheets}
  end
end

defmodule GoogleSheets.WorkSheetData do
  @moduledoc """
  Structure for a spreadsheet worksheet CSV data.

  * :name   - Name of the worksheet
  * :csv    - Raw CSV data split into lines.
  """

  @type t :: %GoogleSheets.WorkSheetData{name: String.t, csv: [String.t]}
  defstruct name: nil, csv: nil

  def new(name, csv) do
    %GoogleSheets.WorkSheetData{name: name, csv: csv}
  end
end

