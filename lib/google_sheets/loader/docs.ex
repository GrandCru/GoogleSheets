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

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData

  @doc """
  Load spreadsheet from the url specified in config[:url] key.
  """
  def load(sheets, previous_version, config) when is_list(sheets) and is_list(config) do
    try do
      url = Keyword.fetch!(config, :url)
      {config, version, sheets} =
        %{sheets: sheets, url: url, previous_version: previous_version}
        |> request_feed
        |> parse_feed_response
        |> parse_feed
        |> filter_sheets
        |> load_csv_content
        |> validate_all_sheets_exist

      {version, SpreadSheetData.new(url, sheets)}
    catch
      :unchanged ->
        # Logger.info "Document #{inspect config[:url]} not changed since #{inspect config[:previous_version]}"
        :unchanged
    end
  end

  #
  # Load atom feed content describing spreadsheet
  #
  defp request_feed(%{} = config) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get config[:url]
    {config, response.body}
  end

  #
  # Parses the atom feed and validate that the response we received is an actual feed for the document
  #
  defp parse_feed_response({%{} = config, response_body}) do
    {:ok, {'{http://www.w3.org/2005/Atom}feed', _, feed}, _} = :erlsom.simple_form response_body
    {config, feed}
  end

  #
  # Parse last updated datetime and CSV content URLs from the atom feeds
  #
  defp parse_feed({%{} = config, feed}) do
    {version, sheets} = parse_feed feed, nil, []

    case config[:previous_version] != nil and version != nil and config[:previous_version] == version do
      true ->
        throw :unchanged
      false ->
        {config, version, sheets}
    end
  end

  # Parse feed entries
  defp parse_feed([], version, sheets) do
    {version, sheets}
  end
  defp parse_feed([{'{http://www.w3.org/2005/Atom}updated', [], [version]} | rest], nil, sheets) do
    parse_feed rest, List.to_string(version), sheets
  end
  defp parse_feed([{'{http://www.w3.org/2005/Atom}entry', _, entry} | rest], version, sheets) do
    parse_feed rest, version, [parse_feed_entry(entry) | sheets]
  end
  defp parse_feed([_node | rest], version, sheets) do
    parse_feed rest, version, sheets
  end

  # Parse individual worksheet entry node in feed
  defp parse_feed_entry(entry) do
    WorkSheetData.new(find_entry_title(entry), find_entry_url(entry))
  end

  # Find the title of of the worksheet
  defp find_entry_title([]), do: nil
  defp find_entry_title([{'{http://www.w3.org/2005/Atom}title', [{'type', 'text'}], [title]} | _t]), do: List.to_string title
  defp find_entry_title([_h | t]), do: find_entry_title t

  # Find the url for csv content for the worksheet
  defp find_entry_url([]), do: nil
  defp find_entry_url([{'{http://www.w3.org/2005/Atom}link', [{'href', url}, {'type', 'text/csv'}, _], []} | _t]), do: List.to_string url
  defp find_entry_url([_h | t]), do: find_entry_url t


  #
  # Filter spreadsheet sheets and leave only those specified in the sheets list, if empty list is given, don't do any filtering
  #
  defp filter_sheets({%{sheets: []} = config, version, sheets}), do: {config, version, sheets}
  defp filter_sheets({%{} = config, version, sheets}) do
    filtered = sheets |> Enum.filter(fn(sheet) -> sheet.name in config[:sheets] end)
    {config, version, filtered}
  end

  #
  # Load the csv content using parsed individual worksheet CSV content URLs.
  #
  defp load_csv_content({%{} = config, version, sheets}) do
    {config, version, load_csv_content(sheets, [])}
  end

  # Recursively loop throug all keys found from the feed
  defp load_csv_content([], []), do: throw({:error, "No sheets loaded"})
  defp load_csv_content([], sheets), do: sheets
  defp load_csv_content([%WorkSheetData{} = sheet | rest], sheets) do
    csv = request_csv_content sheet.src
    load_csv_content rest, [WorkSheetData.update_csv(sheet, csv) | sheets]
  end

  # Fetch and parse the actual CSV content
  defp request_csv_content(url) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url
    response.body
  end

  #
  # Make sure all requested sheets were loaded
  #
  defp validate_all_sheets_exist({%{sheets: []} = config, version, worksheets}), do: {config, version, worksheets}
  defp validate_all_sheets_exist({config, version, worksheets}) do
    true = Enum.all?(config[:sheets], fn(sheet) -> Enum.any?(worksheets, fn(ws) -> ws.name == sheet end) end)
    {config, version, worksheets}
  end

end