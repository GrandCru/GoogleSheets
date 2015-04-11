defmodule GoogleSheets.Loader.FileSystem do

  @moduledoc """
  Implements GoogleSheets.Loader behaviour for reading given spreadsheets in csv format
  from a directory.
  """

  require Logger

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData

  @doc """
  Reads CSV files matching given sheet names from directory. Returns a spreadsheet with
  nil as version information and SpreadSheet.t struct containing data for all given
  spreadsheets.
  """
  def load(sheets, previous_version, config) when is_list(sheets) and is_list(config) do
    path = Path.expand Keyword.fetch!(config, :dir)
    true = File.exists? path
    files = Path.wildcard(path <> "/*.csv") |> filter_files(sheets)
    {version, worksheets} = load_csv_files files, previous_version, []

    case version == previous_version do
      true ->
        :unchanged
      false ->
        validate_all_sheets_exist sheets, worksheets
        {version, SpreadSheetData.new(path, worksheets)}
    end
  end

  # Filter files based on given sheets, unless loading all files (empty sheets argument)
  defp filter_files(files, []), do: files
  defp filter_files(files, sheets) do
    Enum.filter(files, fn(filename) -> Path.basename(filename, ".csv") in sheets end)
  end

  # Make sure there exist an csv file for each sheet to load, unless we load all sheets in directory
  defp validate_all_sheets_exist([], _worksheets), do: true
  defp validate_all_sheets_exist(sheets, worksheets) do
    true = Enum.all?(sheets, fn(sheet) -> Enum.any?(worksheets, fn(ws) -> ws.name == sheet end) end)
  end

  # Could optimize by first comparing the mtime of each file and then a separate pass for loading data
  defp load_csv_files([], modified, worksheets), do: {modified, worksheets}
  defp load_csv_files([file | rest], modified, worksheets) do
    name = Path.basename(file, ".csv")
    csv = File.read! file
    modified = last_modified File.stat!(file), modified
    load_csv_files rest, modified, [WorkSheetData.new(name, file, csv) | worksheets]
  end

  defp last_modified(%File.Stat{} = stat, modified) do
    {{year, month, day}, {hour, min, sec}} = stat.mtime
    file_modified = "#{year}-#{month}-#{day}_#{hour}-#{min}-#{sec}"
    case file_modified < modified do
      true ->
        modified
      false ->
        file_modified
    end
  end

end

