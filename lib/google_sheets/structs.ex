defmodule GoogleSheets.LoaderConfig do
  defstruct key: nil, last_updated: nil, included_sheets: nil
  @type t :: %GoogleSheets.LoaderConfig{key: String.t, last_updated: String.t, included_sheets: [String.t]}
end

defmodule GoogleSheets.SpreadSheetData do
  defstruct hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
end

defmodule GoogleSheets.WorkSheetData do
  defstruct name: nil, url: nil, hash: nil, csv: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, url: String.t, hash: String.t, csv: [String.t]}
end
