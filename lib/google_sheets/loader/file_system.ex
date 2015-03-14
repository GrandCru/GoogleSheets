defmodule GoogleSheets.Loader.FileSystem do

  require Logger

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData

  def load(sheets, _last_updated, config) when is_list(sheets) and is_list(config) do
    path = Path.expand Keyword.fetch!(config, :src)
    files = Path.wildcard(path <> "/*.csv")
    sheets = load_csv_files files, []
    {nil, SpreadSheetData.new(path, sheets)}
  end

  defp load_csv_files([], sheets), do: sheets
  defp load_csv_files([file | rest], sheets) do
    name = Path.basename(file, ".csv")
    csv = File.read! file
    load_csv_files rest, [WorkSheetData.new(name, file, csv) | sheets]
  end

end

