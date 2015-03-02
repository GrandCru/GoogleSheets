
defmodule GoogleSheets.Loader do

  use Pipe
  require Logger

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData
  alias GoogleSheets.LoaderData

  @doc """
  Loads all sheets in the spreadsheet published with the given access key.

  Returns a GoogleSheets.SpreadSheetData structure.

  See the module README.md for information about how to publish Google Spreadsheets
  and how to get the access key.
  """
  def load(%LoaderData{} = data) do
    data
      |> load_feed
      |> parse_response
      |> parse_feed
      |> filter_entries
      |> load_content
      |> concatenated_hash
  end

  #
  # Load atom feed content describing spreadsheet
  #
  defp load_feed(%LoaderData{} = data) do
    data = %LoaderData{data | :feed_url => "https://spreadsheets.google.com/feeds/worksheets/#{data.key}/public/basic"}
    case HTTPoison.get data.feed_url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        %LoaderData{data | :response => response}
      {:ok, _} ->
        Logger.debug "Error loading feed from url #{inspect data.feed_url}"
        %LoaderData{data | :status => :error}
      _ ->
        Logger.error "Internal error in HTTPoison requesting feed url #{inspect data.feed_url}"
        %LoaderData{data | :status => :error}
    end
  end

  #
  # Parses the atom feed and validate that the response we received is an actual feed for the document
  #
  defp parse_response(%LoaderData{:status => :ok} = data) do
    try do
      {:ok, {'{http://www.w3.org/2005/Atom}feed', _, feed}, _} = :erlsom.simple_form data.response.body
      %{data | :feed => feed, :response => nil}
    catch
      _ ->
        Logger.error "Invalid XML document, unable to parse it."
        %LoaderData{data | :status => :error}
    rescue
      _ ->
        Logger.error "Document not matching expected format."
        %LoaderData{data | :status => :error}
    end
  end
  defp parse_response(%LoaderData{} = data), do: data

  #
  # Parse last updated and CSV content URLs from the atom feed
  #
  defp parse_feed(%LoaderData{:status => :ok} = data) do
    {last_updated, worksheets} = parse_feed data.feed, nil, []

    case data.last_updated != nil and last_updated != nil and data.last_updated == last_updated do
      true ->
        %LoaderData{data | :status => :up_to_date, :feed => nil}
      false ->
        %LoaderData{data | :last_updated => last_updated, :worksheets => worksheets, :feed => nil}
    end
  end
  defp parse_feed(%LoaderData{:status => :error} = data), do: data

  defp parse_feed([], updated, worksheets), do: {updated, worksheets}
  defp parse_feed([{'{http://www.w3.org/2005/Atom}updated', [], [last_updated]} | rest], _updated, worksheets), do: parse_feed(rest, last_updated, worksheets)
  defp parse_feed([{'{http://www.w3.org/2005/Atom}entry', _, entry} | rest], updated, worksheets), do: parse_feed(rest, updated, parse_feed_entry(entry, worksheets))
  defp parse_feed([_node | rest], updated, worksheets), do: parse_feed(rest, updated, worksheets)

  # Parse individual worskheet entry nodes in feed
  defp parse_feed_entry(entry, worksheets) do
    title = find_entry_title entry
    url = find_entry_url entry
    [%WorkSheetData{name: title, url: url} | worksheets]
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
  defp filter_entries(%LoaderData{:status => :ok, sheets: nil} = data), do: data
  defp filter_entries(%LoaderData{:status => :ok} = data) do
    filtered = Enum.filter(data.worksheets, fn(ws) -> ws.name in data.sheets end)
    %{data | worksheets: filtered}
  end
  defp filter_entries(%LoaderData{} = data), do: data

  #
  # Load the csv content
  #
  defp load_content(%LoaderData{:status => :ok} = data) do
    case load_content data.worksheets, %SpreadSheetData{} do
      :error ->
        %LoaderData{data | :status => :error}
      spreadsheet ->
        %LoaderData{data | :spreadsheet => spreadsheet}
    end
  end
  defp load_content(%LoaderData{} = data), do: data

  # Recursively loop throug all keys found from the feed
  defp load_content([], spreadsheet), do: spreadsheet
  defp load_content([%WorkSheetData{} = worksheet | rest], spreadsheet) do
    case load_csv_content worksheet.url do
      :error ->
        :error
      {content, hash} ->
        load_content rest, %SpreadSheetData{spreadsheet | sheets: [ %WorkSheetData{worksheet | csv: content, hash: hash} | spreadsheet.sheets]}
    end
  end

  # Fetch and parse the actual CSV content
  defp load_csv_content(url) do
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        {response.body, hash(response.body)}
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
  defp concatenated_hash(%LoaderData{:status => :ok} = data) do
    concatenated = Enum.reduce(data.spreadsheet.sheets, "", fn(ws, acc) -> ws.hash <> acc end)
    spreadsheet = %SpreadSheetData{data.spreadsheet | :hash => hash(concatenated)}
    %LoaderData{data | :spreadsheet => spreadsheet}
  end
  defp concatenated_hash(%LoaderData{} = data), do: data

  # Calculate hash for CSV content
  defp hash(content) do
    GoogleSheets.Utils.hexstring :crypto.hash(hash_func, content)
  end

  defp hash_func do
    {:ok, func} = Application.fetch_env :google_sheets, :hash_func
    func
  end
end