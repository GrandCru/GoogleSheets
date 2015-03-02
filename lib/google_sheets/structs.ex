defmodule GoogleSheets.SpreadSheetData do
  defstruct hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
end

defmodule GoogleSheets.WorkSheetData do
  defstruct name: nil, url: nil, hash: nil, data: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, url: String.t, hash: String.t, data: any}
end

defmodule GoogleSheets.LoaderData do
  defstruct status: :ok, key: nil, last_updated: nil, included_sheets: nil, data: nil, spreadsheet: nil
  @type t :: %GoogleSheets.LoaderData{status: atom, key: String.t, last_updated: String.t, included_sheets: [String.t], data: any, spreadsheet: GoogleSheets.SpreadSheetData.t}
end

# Data persisted into ets
defmodule GoogleSheets.StoredData do
  defstruct last_updated: nil, data: nil
  @type t :: %GoogleSheets.StoredData{last_updated: String.t, data: any}
end