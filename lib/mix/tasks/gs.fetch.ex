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

  @doc false
  def run(args) do
    Application.ensure_all_started(:httpoison)

    {options, _, _} =
      OptionParser.parse(
        args,
        switches: [url: :string, dir: :string],
        aliases: [u: :url, d: :dir]
      )

    # If no commandline options are given, we load all spreadsheets configured for the application
    options =
      if options == [] do
        Application.fetch_env!(:google_sheets, :spreadsheets)
      else
        # Make a list of lists from parsed options
        [{:id, options}]
      end

    fetch_spreadsheets(options)
  end

  defp fetch_spreadsheets([]), do: :ok

  defp fetch_spreadsheets([{_id, config} | rest]) do
    url = Keyword.fetch!(config, :url)

    path =
      case Keyword.fetch!(config, :dir) do
        {app, dir} ->
          Application.app_dir(app, dir)

        dir ->
          dir
      end

    Mix.shell().info("Loading spreadsheet from url #{inspect(url)} and saving to #{path}")
    {:ok, _version, worksheets} = Docs.load(nil, :id, config)

    Enum.map(worksheets, fn ws ->
      filename = Path.join(path, ws.name <> ".csv")
      # Write in raw mode so that we are not changing newlines etc
      File.write!(filename, ws.csv, [:raw])
    end)

    fetch_spreadsheets(rest)
  end
end
