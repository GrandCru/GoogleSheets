defmodule GoogleSheets.Loader.Docs do


  @moduledoc """
  Implements GoogleSheets.Loader behavior by fetching a Spreadsheet through Google spreadsheet API.

  The only configuration value required is :url, which should point to the Atom feed of the spreadsheet.
  See [README](extra-readme.html) how to publish a spreadsheet and find the URL.

  The loader first requests the Atom feed and parses URLs pointing to CSV data for each individual
  worksheet and the last_udpdated time stamp for spreadsheet.

  If the last_updated field is equal to the one passes as previous_version, the loader stops and returns :unchanged

  If not, it will filter the found CSV URLs and leave only those that exist in the sheets argument. If the sheets argument
  is nil, it will load all worksheets.

  After requesting all URLs and parsing the responses, the loader checks that each individual spreadsheet given as sheets
  parameter exist and returns an SpreadSheetData.t structure.

  If there are any errors during HTTP requests and/or parsing, it will most likely raise an exception. If you use this
  loader in code which is not crash resistant, do handle the exceptions.
  """
  import SweetXml
  require Logger

  @behaviour GoogleSheets.Loader
  @connect_timeout 2_000
  @receive_timeout 120_000

  @doc """
  Load spreadsheet from Google sheets using the URL specified in config[:url] key.
  """
  def load(previous_version, _id, config) when is_list(config) do
    try do
      url = Keyword.fetch! config, :url
      sheets = Keyword.get config, :sheets, []
      load_spreadsheet previous_version, url, sheets
    catch
      result -> result
    end
  end

  # Fetch Atom feed describing feed and request individual sheets if not modified.
  defp load_spreadsheet(previous_version, url, sheets) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url, [], [timeout: @connect_timeout, recv_timeout: @receive_timeout]

    updated = response.body |> xpath(~x"//feed/updated/text()") |> List.to_string |> String.strip
    version = :crypto.hash(:sha, url <> Enum.join(sheets) <> updated) |> Base.encode16(case: :lower)

    if previous_version != nil and version == previous_version do
      throw {:ok, :unchanged}
    end

    worksheets = response.body
    |> xpath(~x"//feed/entry"l, title: ~x"./title/text()", url: ~x"./link[@type='text/csv']/@href")
    |> convert_entries([])
    |> filter_entries(sheets, [])
    |> load_worksheets([])

    if not Enum.all?(sheets, fn sheetname -> Enum.any?(worksheets, fn ws -> sheetname == ws.name end) end) do
      loaded = worksheets |> Enum.map(fn ws -> ws.name end) |> Enum.join(",")
      throw {:error, "All requested sheets not loaded, expected: #{Enum.join(sheets, ",")} loaded: #{loaded}"}
    end

    {:ok, version, worksheets}
  end

  # Converts xpath entries to {title, url} with data converted to strings
  defp convert_entries([], acc), do: acc
  defp convert_entries([entry | rest], acc) do
    title = List.to_string entry[:title]
    url = List.to_string entry[:url]
    convert_entries rest, [{title, url} | acc]
  end

  # Filter out entries not specified in sheets list, if empty sheets list, accept all
  defp filter_entries(entries, [], _acc), do: entries
  defp filter_entries([], _sheets, acc), do: acc
  defp filter_entries([{title, url} | rest], sheets, acc) do
    if title in sheets do
      acc = [{title, url} | acc]
    end
    filter_entries rest, sheets, acc
  end

  # Request worksheets and create WorkSheet.t entries
  defp load_worksheets([], worksheets), do: worksheets
  defp load_worksheets([{title, url} | rest], worksheets) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url, [], [timeout: @connect_timeout, recv_timeout: @receive_timeout]
    load_worksheets rest, [%GoogleSheets.WorkSheet{name: title, csv: response.body} | worksheets]
  end

end