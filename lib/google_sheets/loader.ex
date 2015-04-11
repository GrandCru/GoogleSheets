defmodule GoogleSheets.Loader do

  use Behaviour

  @moduledoc """
  Behaviour for a spreadsheet loader.

  Each module implementing this behaviour is expected to load CSV data from a source and return SpreadSheetData.t structure.
  """

  @doc """
  The load callback can be called by and updater process or by any other process wishing to load data.

  The parameters:

  * sheets - A list of worksheets to load, if empty all worksheets available are to be loaded.
  * previous_version - Value returned by a previous call to loader or nil. All loaders should implement some
  way to check that data loaded is equal to previous load. In worst case it is possible to use hash value of spreadsheet
  for equality comparison, but in many cases there is a last modified timestamp or some other way to do this without
  loading all data. For example, the Docs loader uses <updated> element value of the atom feed.
  * config - Loader specific configuration options, for example might contain directory where to laod data or URL.

  Return values:

  * {version, spreadsheet} - Tuple with version information and SpreadSheetData.t structure. The version parameter can be nil, if the loader can't or doesn't implement optimizations.
  * :unchanged - No changes since last load time.
  * :error - Unspecified error, will restart the udpater process.

  The sheets parameter is a list of Worksheet names to load, if nill
  """
  defcallback load(sheets :: [binary], previous_version :: binary | nil, config :: Keyword.t) :: {version :: binary, spreadsheet :: GoogleSheets.SpreadSheetData.t} | :unchanged | :error
end

defmodule GoogleSheets.SpreadSheetData do
  @moduledoc """
  Structure containg a spreadsheet data in CSV format.
  """

  defstruct src: nil, hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{src: String.t, hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}

  def new(src, sheets) when is_list(sheets) do
    # Sort sheets so that we get repeatable hashes
    sheets = sheets |> Enum.sort(fn(a,b) -> a.name > b.name end)
    hash = Enum.reduce(sheets, "", fn(sheet, acc) -> sheet.hash <> acc end)
    hash = :crypto.hash(:md5, hash) |> GoogleSheets.Utils.hexstring

    %GoogleSheets.SpreadSheetData{src: src, sheets: sheets, hash: hash}
  end
end

defmodule GoogleSheets.WorkSheetData do
  @moduledoc """
  Structure for a spreadsheet worksheet CSV data.
  """

  defstruct name: nil, src: nil, hash: nil, csv: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, src: String.t, hash: String.t, csv: [String.t]}

  def new(name, src, csv) do
    %GoogleSheets.WorkSheetData{name: name, src: src, csv: csv, hash: GoogleSheets.Utils.hexstring(:crypto.hash(:md5, csv))}
  end
end

