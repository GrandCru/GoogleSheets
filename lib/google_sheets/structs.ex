defmodule GoogleSheets.SpreadSheetData do
  defstruct hash: nil, sheets: [], data: nil
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
end

defmodule GoogleSheets.WorkSheetData do
  defstruct name: nil, hash: nil, csv: nil, url: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, hash: String.t, csv: String.t}
end

defmodule GoogleSheets.LoaderData do
  defstruct status: :ok, key: nil, last_updated: nil, sheets: nil, response: nil, feed_url: nil, feed: nil, worksheets: nil, spreadsheet: nil
end
