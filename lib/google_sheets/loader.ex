defmodule GoogleSheets.Loader do
  @moduledoc """
  Implementing classes can load data with information specified in LoaderConfig struct and return
  a SpreadSheetData structure containing CSV and associated metadata.
  """
  use Behaviour
  defcallback load(sheets :: [binary], last_updated :: binary | nil, config :: Keyword.t) :: GoogleSheets.SpreadSheetData.t | :unchanged | :error
end

defmodule GoogleSheets.SpreadSheetData do
  @moduledoc """
  Container for individual worksheets, hash is the combined hash of all loaded worksheets.
  """

  defstruct hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}

  def new(sheets) when is_list(sheets) do
    # Sort sheets so that we get repeatable hashes
    sheets = sheets |> Enum.sort(fn(a,b) -> a.name > b.name end)
    hash = Enum.reduce(sheets, "", fn(sheet, acc) -> sheet.hash <> acc end)
    hash = :crypto.hash(:md5, hash) |> GoogleSheets.Utils.hexstring

    %GoogleSheets.SpreadSheetData{sheets: sheets, hash: hash}
  end
end

defmodule GoogleSheets.WorkSheetData do
  @moduledoc """
  Data for a single individual worksheet in a spreadsheet.
  """

  defstruct name: nil, url: nil, hash: nil, csv: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, url: String.t, hash: String.t, csv: [String.t]}

  def new(name, csv, url \\ nil) do
    %GoogleSheets.WorkSheetData{name: name, csv: csv, hash: GoogleSheets.Utils.hexstring(:crypto.hash(:md5, csv)), url: url}
  end

  def put_csv(worksheet, csv) do
    %GoogleSheets.WorkSheetData{worksheet | csv: csv, hash: GoogleSheets.Utils.hexstring(:crypto.hash(:md5, csv))}
  end
end

