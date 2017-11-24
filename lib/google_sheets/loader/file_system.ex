defmodule GoogleSheets.Loader.FileSystem do

  @moduledoc """
  Implements GoogleSheets.Loader behavior for reading given spreadsheets in CSV format
  from a directory.
  """

  @behaviour GoogleSheets.Loader

  @doc """
  Reads CSV files from config[:dir] directory.
  """
  def load(previous_version, _id, config) when is_list(config) do
    try do
      dir = Keyword.fetch! config, :dir
      ignored_sheets = Keyword.get config, :ignored_sheets, []
      sheets =
        config
        |> Keyword.get(:sheets, [])
        |> Enum.reject(fn sheet -> sheet in ignored_sheets end)
      load_spreadsheet(previous_version, dir, sheets)
    catch
      result -> result
    end
  end

  defp load_spreadsheet(previous_version, {app, dir}, sheets) when is_atom(app) do
    load_spreadsheet(previous_version, Application.app_dir(app, dir), sheets)
  end

  defp load_spreadsheet(previous_version, dir, sheets) do
    path = Path.expand dir
    if not File.exists? path do
      throw {:error, "Can't load CSV files from non existing directory #{inspect path}"}
    end

    files = Path.wildcard(path <> "/*.csv")
    worksheets = load_files(files, sheets, [])

    if not Enum.all?(sheets, fn sheetname -> Enum.any?(worksheets, fn ws -> ws.name == sheetname end) end) do
      loaded = worksheets
      |> Enum.map(fn ws -> ws.name end)
      |> Enum.join(",")
      throw {:error, "All requested worksheets were not found, expected to load #{inspect sheets} loaded: #{inspect loaded}"}
    end

    version = calculate_version(worksheets)
    if version == previous_version do
      throw {:ok, :unchanged}
    end

    {:ok, version, worksheets}
  end

  # Load CSV files and filter if only specific sheets should be loaded
  defp load_files([], _sheets, worksheets), do: worksheets
  defp load_files([filename | rest], sheets, worksheets) do
    sheetname = Path.basename filename, ".csv"

    if sheets == [] or sheetname in sheets do
      csv = File.read! filename
      worksheets = [%GoogleSheets.WorkSheet{name: sheetname, csv: csv} | worksheets]
      load_files(rest, sheets, worksheets)
    else
      load_files(rest, sheets, worksheets)
    end
  end

  # Calculate version based on CSV data
  defp calculate_version(worksheets) when is_list(worksheets) do
    concatenated = worksheets |> Enum.sort(fn a,b -> a.name <= b.name end) |> Enum.reduce("", fn ws, acc -> ws.csv <> acc end)
    :crypto.hash(:sha, concatenated) |> Base.encode16(case: :lower)
  end

end
