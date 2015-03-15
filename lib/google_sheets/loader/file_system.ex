defmodule GoogleSheets.Loader.FileSystem do

  require Logger

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData

  def load(sheets, _last_updated, config) when is_list(sheets) and is_list(config) do
    path = Path.expand Keyword.fetch!(config, :src)
    if File.exists? path do
      files = Path.wildcard(path <> "/*.csv") |> filter_files(sheets)
      loaded = load_csv_files files, []
      {nil, SpreadSheetData.new(path, loaded)}
    else
      :error
    end
  end

  # No filtering if nil or empty list given
  defp filter_files(files, []), do: files
  defp filter_files(files, sheets) do
    Enum.filter(files, fn(filename) -> Path.basename(filename, ".csv") in sheets end)
  end

  defp load_csv_files([], worksheets), do: worksheets
  defp load_csv_files([file | rest], worksheets) do
    name = Path.basename(file, ".csv")
    csv = File.read! file
    load_csv_files rest, [WorkSheetData.new(name, file, csv) | worksheets]
  end

end

