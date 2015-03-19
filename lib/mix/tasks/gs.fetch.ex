defmodule Mix.Tasks.Gs.Fetch do
  use Mix.Task

  @shortdoc "Fetch Google Spreadsheet and save raw CSV to disk"

  @moduledoc """
  Loads a Google spreadsheet and all worksheets in CSV format for the given document key.

  ## Examples
  mix gs.fetch -k 1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs -d priv/data

  ## Command line options
  * -u, --url - Source URL to a published Spreadsheet, see README.md for more information.
  * -d, --dir - Directory where to save all CSV files, relative to application root path.
  """

  alias GoogleSheets.Loader.Docs

  def run(args) do
    Mix.Task.run "app.start", args
    {options, _, _} = OptionParser.parse args, switches: [url: :string, dir: :string], aliases: [u: :url, d: :dir]

    path = Path.expand Keyword.fetch!(options, :dir)
    File.mkdir_p! path

    {_updated, spreadsheet} = Docs.load [], nil, [url: Keyword.fetch!(options, :url)]
    write_sheets spreadsheet.sheets, path
  end

  defp write_sheets([], _path), do: nil
  defp write_sheets([sheet | rest], path) do
    filename = Path.join(path, sheet.name) <> ".csv"
    Mix.shell.info "Writing file #{filename}"
    File.write! filename, sheet.csv
    write_sheets rest, path
  end

end