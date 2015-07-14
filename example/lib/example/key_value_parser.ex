defmodule Example.KeyValueParser do

  @behaviour GoogleSheets.Callback

  # Just a pass through converted, doesn't actually do any parsing
  def on_loaded(previous_version, %GoogleSheets.SpreadSheetData{} = spreadsheet) do
    spreadsheet
  end

end