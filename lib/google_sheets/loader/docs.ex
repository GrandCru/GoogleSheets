defmodule GoogleSheets.Loader.Docs do

  require Logger

  @behaviour GoogleSheets.Loader

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData
  alias GoogleSheets.Utils

  @doc """
  Loads all sheets in the spreadsheet published with the given access key.
  """
  def load(sheets, last_updated, config) when is_list(sheets) and is_list(config) do
    try do
      {config, updated, sheets} =
        %{sheets: sheets, key: Keyword.fetch!(config, :key), last_updated: last_updated}
        |> request_feed
        |> parse_feed_response
        |> parse_feed
        |> filter_sheets
        |> load_csv_content

      {updated, %SpreadSheetData{sheets: sheets, hash: Utils.calculate_combined_hash(sheets)} }
    catch
      :unchanged ->
        Logger.info "Document #{inspect config[:key]} not changed since #{inspect config[:last_updated]}"
        :unchanged
    end
  end

  #
  # Load atom feed content describing spreadsheet
  #
  defp request_feed(%{} = config) do
    url = "https://spreadsheets.google.com/feeds/worksheets/#{config[:key]}/public/basic"
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url
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
  # Parse last updated and CSV content URLs from the atom feeds
  #
  defp parse_feed({%{} = config, feed}) do
    {last_updated, sheets} = parse_feed feed, nil, []

    case config[:last_updated] != nil and last_updated != nil and config[:last_updated] == last_updated do
      true ->
        throw :unchanged
      false ->
        {config, last_updated, sheets}
    end
  end

  # Parse feed entries
  defp parse_feed([], updated, sheets) do
    {updated, sheets}
  end
  defp parse_feed([{'{http://www.w3.org/2005/Atom}updated', [], [last_updated]} | rest], _updated, sheets) do
    parse_feed rest, last_updated, sheets
  end
  defp parse_feed([{'{http://www.w3.org/2005/Atom}entry', _, entry} | rest], updated, sheets) do
    parse_feed rest, updated, [parse_feed_entry(entry) | sheets]
  end
  defp parse_feed([_node | rest], updated, sheets) do
    parse_feed rest, updated, sheets
  end

  # Parse individual worksheet entry node in feed
  defp parse_feed_entry(entry) do
    %WorkSheetData{name: find_entry_title(entry), url: find_entry_url(entry)}
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
  # Filter spreadsheet sheets and leave only those specified in the sheets list, if no list is given, don't do any filtering
  #
  defp filter_sheets({%{} = config, updated, sheets}) do
    filtered = sheets |> Enum.filter(fn(sheet) -> sheet.name in config[:sheets] end)
    {config, updated, filtered}
  end

  #
  # Load the csv content using parsed individual worksheet CSV content URLs.
  #
  defp load_csv_content({%{} = config, updated, sheets}) do
    {config, updated, load_csv_content(sheets, [])}
  end

  # Recursively loop throug all keys found from the feed
  defp load_csv_content([], []), do: throw({:error, "No sheets loaded"})
  defp load_csv_content([], sheets), do: sheets
  defp load_csv_content([%WorkSheetData{} = sheet | rest], sheets) do
    {csv, hash} = request_csv_content sheet.url
    load_csv_content rest, [%WorkSheetData{sheet | csv: csv, hash: hash} | sheets]
  end

  # Fetch and parse the actual CSV content
  defp request_csv_content(url) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url
    {response.body, Utils.hexstring(:crypto.hash(:md5, response.body))}
  end
end