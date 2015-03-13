defmodule GoogleSheets.Loader.FileSystem do

  require Logger

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData
  alias GoogleSheets.Utils

  def load(sheets, last_updated, config) when is_list(sheets) and is_list(config) do
    :unchanged
  end

end

