defmodule GoogleSheets.Loader.Docs do


  @moduledoc """
  Implemnts GoogleSheets.Loader behaviour by fetching a Spreadsheet with Google spreadsheet API.

  The only loader specific configuration value is :url, which should point to the Atom feed describing
  the worksheet. See README.md for more detailed information about how to publish a spreadsheet and
  find the URL.

  The loader first requests the Atom feed and parses URLs pointing to CSV data for each individual
  worksheet and the last_udpdated timestamp for spreadsheet.

  If the last_updated field is equal to the one passes as previous_version, the loader stops and returns :unchanged

  If not, it will filter the found CSV urls and leave only those that exist in the sheets argument. If the sheets argument
  is nil, it will load all worksheets.

  After requesting all urls and parsing the responses, the loader checks that each invidivual spreadsheet given as sheets
  parameter exist and returns an SpreadSheetData.t structure.

  If there are any errors during http requests and/or parsing, it will most likely raise an expection. If you use this
  loader in code which is not crash resistant, do handle the exceptions.
  """
  require Logger
  import SweetXml

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData

  @doc """
  Load spreadsheet from the url specified in config[:url] key.
  """
  def load(sheets, previous_version, config) when is_list(sheets) and is_list(config) do
    try do
      {version, worksheets} = load_spreadsheet sheets, previous_version, Keyword.fetch!(config, :url)
      {version, SpreadSheetData.new(Keyword.fetch!(config, :url), worksheets)}
    catch
      :unchanged ->
        # Logger.info "Document #{inspect config[:url]} not changed since #{inspect config[:previous_version]}"
        :unchanged
    end
  end

  # Load spreadsheet data
  defp load_spreadsheet(sheets, previous_version, url) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url

    updated = response.body |> xpath(~x"//feed/updated/text()")
    if previous_version != nil and updated == previous_version do
      throw :unchanged
    end

    worksheets = response.body
      |> xpath(~x"//feed/entry"l, title: ~x"./title/text()", url: ~x"./link[@type='text/csv']/@href")
      |> filter_entries(sheets, [])
      |> load_worksheets([])
      |> validate_all_sheets_loaded(sheets)

    {updated, worksheets}
  end

  # Filter out entries not specified in sheets list
  defp filter_entries(entries, [], _acc), do: entries
  defp filter_entries([], _sheets, acc), do: acc
  defp filter_entries([entry | rest], sheets, acc) do
    case List.to_string(entry[:title]) in sheets do
      true -> filter_entries rest, sheets, [entry | acc]
      false -> filter_entries rest, sheets, acc
    end
  end

  # Request worksheets and create WorkSheetData.t entries
  defp load_worksheets([], worksheets), do: worksheets
  defp load_worksheets([entry | rest], worksheets) do
    url = List.to_string entry[:url]
    title = List.to_string entry[:title]
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url
    load_worksheets rest, [WorkSheetData.new(title, url, response.body) | worksheets]
  end

  # Make sure all requested sheets were loaded
  defp validate_all_sheets_loaded(worksheets, []), do: worksheets
  defp validate_all_sheets_loaded(worksheets, sheets) do
    true = Enum.all?(sheets, fn(sheet) -> Enum.any?(worksheets, fn(ws) -> ws.name == sheet end) end)
    worksheets
  end

end