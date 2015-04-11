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
    version = last_modified files, nil

    case version == previous_version do
      true ->
        :unchanged
      false ->
        worksheets = load_csv_files files, []
        true = all_sheets_loaded? sheets, worksheets
        {version, SpreadSheetData.new(path, worksheets)}
    end
  end

  # Filter files based on given sheets, unless loading all files (empty sheets argument)
  defp filter_files(files, []), do: files
  defp filter_files(files, sheets) do
    Enum.filter(files, fn(filename) -> Path.basename(filename, ".csv") in sheets end)
  end

  # Find the newest modified version of files
  defp last_modified([], version), do: version
  defp last_modified([file | rest], version) do
    stat = File.stat! file
    {{year, month, day}, {hour, min, sec}} = stat.mtime
    file_version = "#{year}-#{month}-#{day}_#{hour}-#{min}-#{sec}"
    case file_version < version do
      true ->
        version
      false ->
        file_version
    end
  end

  # Make sure there exist an csv file for each sheet to load, unless we load all sheets in directory
  defp all_sheets_loaded?([], _worksheets), do: true
  defp all_sheets_loaded?(sheets, worksheets) do
    Enum.all?(sheets, fn(sheet) -> Enum.any?(worksheets, fn(ws) -> ws.name == sheet end) end)
  end

  # Load CSV data
  defp load_csv_files([], worksheets), do: worksheets
  defp load_csv_files([file | rest], worksheets) do
    csv = File.read! file
    name = Path.basename(file, ".csv")
    load_csv_files rest, [WorkSheetData.new(name, file, csv) | worksheets]
  end

end
