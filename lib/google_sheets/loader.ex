defmodule GoogleSheets.Loader do
  @moduledoc """
  Implementing classes can load data with information specified in LoaderConfig struct and return
  a SpreadSheetData structure containing CSV and associated metadata.
  """
  use Behaviour
  defcallback load(cfg :: GoogleSheets.LoaderConfig.t) :: GoogleSheets.SpreadSheetData.t | :unchanged
end

defmodule GoogleSheets.LoaderConfig do
  @moduledoc """
  Defines required information for loading spreadsheet data.
  """
  defstruct key: nil, sheets: nil, last_updated: nil
  @type t :: %GoogleSheets.LoaderConfig{key: String.t, sheets: [String.t], last_updated: String.t}
end

defmodule GoogleSheets.SpreadSheetData do
  @moduledoc """
  Container for individual worksheets, hash is the combined hash of all loaded worksheets.
  """
  defstruct hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
end

defmodule GoogleSheets.WorkSheetData do
  @moduledoc """
  Data for a single individual worksheet in a spreadsheet.
  """
  defstruct name: nil, url: nil, hash: nil, csv: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, url: String.t, hash: String.t, csv: [String.t]}
end

