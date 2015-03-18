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
  def load(sheets, _previous_version, config) when is_list(sheets) and is_list(config) do
    path = Path.expand Keyword.fetch!(config, :src)
    true = File.exists? path
    files = Path.wildcard(path <> "/*.csv") |> filter_files(sheets)
    worksheets = load_csv_files files, []
    validate_all_sheets_exist sheets, worksheets
    {nil, SpreadSheetData.new(path, worksheets)}
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

  defp load_csv_files([], worksheets), do: worksheets
  defp load_csv_files([file | rest], worksheets) do
    name = Path.basename(file, ".csv")
    csv = File.read! file
    load_csv_files rest, [WorkSheetData.new(name, file, csv) | worksheets]
  end

end

