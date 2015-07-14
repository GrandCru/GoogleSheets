defmodule Mix.Tasks.Gs.Fetch do

  use Mix.Task
  require Logger

  alias GoogleSheets.Loader.Docs

  @shortdoc "Fetch Google Spreadsheet and save raw CSV to disk"

  @moduledoc """
  Loads a Google spreadsheet and all worksheets in CSV format for the given document key.

  If no parameters are given, it looks through all configured spreadsheets in :google_sheets configuration.

  ## Examples
  mix gs.fetch -u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic -d priv/data

  ## Command line options
  * -u, --url - Source URL to a published Spreadsheet, see README.md for more information.
  * -d, --dir - Directory where to save all CSV files, relative to application root path.
  """

  def run(args) do
    Application.ensure_all_started :httpoison
    {options, _, _} = OptionParser.parse args, switches: [url: :string, dir: :string], aliases: [u: :url, d: :dir]

    # If no commandline options are given, we load all spreadsheets configured for the application
    if options == [] do
      {:ok, options} = Application.fetch_env :google_sheets, :spreadsheets
    else
      # Make a list of lists from parsed options
      options = [options]
    end

    fetch_spreadsheets options
  end

  defp fetch_spreadsheets([]), do: :ok
  defp fetch_spreadsheets([config | rest]) do
    url = Keyword.fetch! config, :url
    dir = Keyword.fetch! config, :dir
    path = Path.expand dir

    Mix.shell.info "Loading spreadsheet from url #{inspect url} and saving to #{path}"
    {:ok, spreadsheet} = Docs.load nil, config

    Enum.map spreadsheet.sheets, fn ws ->
      filename = Path.join path, ws.name <> ".csv"
      Mix.shell.info "Writing file #{filename}"
      File.write! filename, ws.csv
    end

    fetch_spreadsheets rest
  end

end
