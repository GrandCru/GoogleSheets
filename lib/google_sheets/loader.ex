
defmodule GoogleSheets.Loader do

  require Logger

  alias GoogleSheets.LoaderConfig
  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData
  alias GoogleSheets.Utils

  @doc """
  Loads all sheets in the spreadsheet published with the given access key.
  """
  def load(%LoaderConfig{} = config) do
    try do
      config
        |> load_feed
        |> parse_response
        |> parse_feed
        |> filter_entries
        |> load_content
        |> calculate_hash
        |> create_response
    catch
      :unchanged ->
        Logger.info "Document #{inspect config.key} not changed since #{inspect config.last_updated}"
        :unchanged
    end
  end

  @doc """
  Load atom feed content describing spreadsheet
  """
  def load_feed(%LoaderConfig{} = config) do
    url = "https://spreadsheets.google.com/feeds/worksheets/#{config.key}/public/basic"
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url
    {config, response.body}
  end

  @doc """
  Parses the atom feed and validate that the response we received is an actual feed for the document
  """
  def parse_response({%LoaderConfig{} = config, response_body}) do
    {:ok, {'{http://www.w3.org/2005/Atom}feed', _, feed}, _} = :erlsom.simple_form response_body
    {config, feed}
  end

  @doc """
  Parse last updated and CSV content URLs from the atom feeds
  """
  def parse_feed({%LoaderConfig{} = config, feed}) do
    {last_updated, sheets} = parse_feed feed, nil, []

    case config.last_updated != nil and last_updated != nil and config.last_updated == last_updated do
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


  @doc """
  Filter spreadsheet sheets and leave only those specified in the sheets list, if no list is given, don't do any filtering
  """
  def filter_entries({%LoaderConfig{} = config, updated, sheets}) do
    filtered = sheets
      |> filter_included(config.included)
      |> filter_excluded(config.excluded)

    {config, updated, filtered}
  end

  defp filter_included(sheets, nil), do: sheets
  defp filter_included(sheets, included), do: Enum.filter(sheets, fn(sheet) -> sheet.name in included end)

  defp filter_excluded(sheets, nil), do: sheets
  defp filter_excluded(sheets, excluded), do: Enum.filter(sheets, fn(sheet) -> not sheet.name in excluded end)

  @doc """
  Load the csv content
  """
  def load_content({%LoaderConfig{} = config, updated, sheets}) do
    {config, updated, load_content(sheets, [])}
  end

  # Recursively loop throug all keys found from the feed
  defp load_content([], []), do: throw({:error, "No sheets loaded"})
  defp load_content([], sheets), do: sheets
  defp load_content([%WorkSheetData{} = sheet | rest], sheets) do
    {csv, hash} = load_csv_content sheet.url
    load_content rest, [%WorkSheetData{sheet | csv: csv, hash: hash} | sheets]
  end

  # Fetch and parse the actual CSV content
  defp load_csv_content(url) do
    {:ok, %HTTPoison.Response{status_code: 200} = response} = HTTPoison.get url
    {response.body, Utils.hexstring(:crypto.hash(:md5, response.body))}
  end

  @doc """
  Calculate concatenated hash for all worksheets
  """
  def calculate_hash({%LoaderConfig{} = config, updated, sheets}) do
    hash = Utils.hexstring(:crypto.hash(:md5, Enum.reduce(sheets, "", fn(sheet, acc) -> sheet.hash <> acc end)))
    {config, updated, sheets, hash}
  end

  @doc """
  Construct response
  """
  def create_response({%LoaderConfig{}, updated, sheets, hash}) do
    {updated, %SpreadSheetData{sheets: sheets, hash: hash}}
  end
end