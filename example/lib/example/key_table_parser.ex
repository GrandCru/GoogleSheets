defmodule Example.KeyTableParser do

  @behaviour GoogleSheets.Callback

  def on_loaded(previous_version, %GoogleSheets.SpreadSheetData{} = spreadsheet) do
    spreadsheet
  end

end