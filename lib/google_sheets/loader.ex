
defmodule GoogleSheets.Loader do

  require Logger

  alias GoogleSheets.LoaderConfig
  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData
  alias GoogleSheets.Utils

  @doc """
  Loads all sheets in the spreadsheet published with the given access key.

  Returns a GoogleSheets.SpreadSheetData structure.

  See the module README.md for information about how to publish Google Spreadsheets
  and how to get the access key.
  """
  def load(%LoaderConfig{} = config) do
    result =
      config
      |> load_feed
      |> parse_response
      |> parse_feed
      |> filter_entries
      |> load_content
      |> calculate_hash
      |> create_response
  end

  #
  # Load atom feed content describing spreadsheet
  #
  defp load_feed(%LoaderConfig{} = config) do
    url = "https://spreadsheets.google.com/feeds/worksheets/#{config.key}/public/basic"
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        {config, response.body}
      {:ok, _} ->
        Logger.error "Error loading feed from url #{url}"
        :error
      _ ->
        Logger.error "Internal error in HTTPoison requesting feed url #{url}"
        :error
    end
  end

  #
  # Parses the atom feed and validate that the response we received is an actual feed for the document
  #
  defp parse_response({%LoaderConfig{} = config, response_body}) do
    try do
      {:ok, {'{http://www.w3.org/2005/Atom}feed', _, feed}, _} = :erlsom.simple_form response_body
      {config, feed}
    catch
      _ ->
        Logger.error "Invalid XML document, unable to parse it."
        :error
    rescue
      _ ->
        Logger.error "Document not matching expected format."
        :error
    end
  end
  defp parse_response(result), do: result

  #
  # Parse last updated and CSV content URLs from the atom feed
  #
  defp parse_feed({%LoaderConfig{} = config, feed}) do
    {last_updated, sheets} = parse_feed feed, nil, []

    case config.last_updated != nil and last_updated != nil and config.last_updated == last_updated do
      true ->
        :unchanged
      false ->
        {config, last_updated, sheets}
    end
  end
  defp parse_feed(result), do: result

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
  defp filter_entries({%LoaderConfig{} = config, updated, sheets}) do
    filtered = sheets
      |> filter_included(config.included)
      |> filter_excluded(config.excluded)

    {config, updated, filtered}
  end
  defp filter_entries(result), do: result

  defp filter_included(sheets, nil), do: sheets
  defp filter_included(sheets, included), do: Enum.filter(sheets, fn(sheet) -> sheet.name in included end)

  defp filter_excluded(sheets, nil), do: sheets
  defp filter_excluded(sheets, excluded), do: Enum.filter(sheets, fn(sheet) -> not sheet.name in excluded end)
  #
  # Load the csv content
  #
  defp load_content({%LoaderConfig{} = config, updated, sheets}) do
    case load_content sheets, [] do
      sheets when is_list(sheets) ->
        {config, updated, sheets}
      :error ->
        :error
    end
  end
  defp load_content(result), do: result

  # Recursively loop throug all keys found from the feed
  defp load_content([], sheets), do: sheets
  defp load_content([%WorkSheetData{} = sheet | rest], sheets) do
    case load_csv_content sheet.url do
      {csv, hash} ->
        load_content rest, [%WorkSheetData{sheet | csv: csv, hash: hash} | sheets]
      :error ->
        :error
    end
  end

  # Fetch and parse the actual CSV content
  defp load_csv_content(url) do
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        {response.body, Utils.hexstring(:crypto.hash(:md5, response.body))}
      {:ok, response} ->
        Logger.error "Error loading CSV content from url #{url} status: #{inspect response.status_code}"
        :error
      _ ->
        Logger.error "Error loading CSV content from url #{url}"
        :error
    end
  end

  #
  # Calculate concatenated hash for all worksheets
  #
  defp calculate_hash({%LoaderConfig{} = config, updated, sheets}) do
    hash =  Utils.hexstring(:crypto.hash(:md5, Enum.reduce(sheets, "", fn(sheet, acc) -> sheet.hash <> acc end)))
    {config, updated, sheets, hash}
  end
  defp calculate_hash(result), do: result

  #
  # Construct response
  #
  defp create_response({%LoaderConfig{} = config, updated, sheets, hash}) do
    {updated, %SpreadSheetData{sheets: sheets, hash: hash}}
  end
  defp create_response(result), do: result
end