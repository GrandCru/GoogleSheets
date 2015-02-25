defmodule GoogleSheets.SpreadSheetData do
  defstruct hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
end

defmodule GoogleSheets.WorkSheetData do
  defstruct name: nil, hash: nil, csv: nil, url: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, hash: String.t, csv: String.t}
end
