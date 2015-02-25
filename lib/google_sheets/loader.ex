defmodule GoogleSheets.Loader do

  use Pipe
  require Logger

  alias GoogleSheets.SpreadSheetData
  alias GoogleSheets.WorkSheetData

  @doc """
  Loads all sheets in the spreadsheet published with the given access key.

  Returns a GoogleSheets.SpreadSheetData structure.

  See the module README.md for information about how to publish Google Spreadsheets
  and how to get the access key.
  """
  def load(key, sheets \\ []) do
    pipe_matching {:ok, _},
      load_feed(key)
      |> parse_response
      |> parse_feed
      |> filter_entries(sheets)
      |> load_content
      |> concatenated_hash
  end

  defp load_feed(key) do
    url = "https://spreadsheets.google.com/feeds/worksheets/#{key}/public/basic"
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        {:ok, response}
      {:ok, _} ->
        {:error, "Request failed to url #{inspect url}"}
      _ ->
        {:error, "Internal error in HTTPoison requesting url #{inspect url}"}
    end
  end

  # Parses and validates that the response we received is an actual feed for the document
  defp parse_response({:ok, response}) do
    try do
      {:ok, {'{http://www.w3.org/2005/Atom}feed', _, feed}, _} = :erlsom.simple_form response.body
      {:ok, feed}
    catch
      _ -> {:error, "Invalid XML document, unable to parse it."}
    rescue
      _ -> {:error, "Document not matching expected format."}
    end
  end

  # Parse spreadsheet feed content
  defp parse_feed({:ok, feed}) do
    {:ok, parse_feed(feed, [])}
  end

  defp parse_feed([], worksheets), do: worksheets
  defp parse_feed([{'{http://www.w3.org/2005/Atom}entry', _, entry} | rest], worksheets), do: parse_feed(rest, parse_entry(entry, worksheets))
  defp parse_feed([_node | rest], worksheets), do: parse_feed(rest, worksheets)

  # Parse individual worskheet entry nodes in feed
  defp parse_entry(entry, worksheets) do
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

  # Filter spreadsheet sheets and leave only those specified in the sheets list, if no list is given, don't do any filtering
  defp filter_entries({:ok, worksheets}, []), do: {:ok, worksheets}
  defp filter_entries({:ok, worksheets}, sheets) do
    filtered = Enum.filter(worksheets, fn(ws) -> ws.name in sheets end)
    {:ok, filtered}
  end

  # Load the csv content
  defp load_content({:ok, worksheets}) do
    load_content(worksheets, %SpreadSheetData{})
  end

  # Recursively loop throug all keys found from the feed
  defp load_content([], data), do: {:ok, data}
  defp load_content([%WorkSheetData{} = worksheet | rest], data) do
    case load_csv_content worksheet.url do
      {:ok, content, hash} ->
        load_content rest, %SpreadSheetData{data | sheets: [ %WorkSheetData{worksheet | csv: content, hash: hash} | data.sheets]}
      {:error, msg} ->
        {:error, msg}
    end
  end

  # Fetch and parse the actual CSV content
  defp load_csv_content(url) do
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} -> {:ok, response.body, hash(response.body)}
      {:ok, response} -> {:error, "Error loading CSV content from url #{url} status: #{inspect response.status_code}"}
      {_} -> {:error, "Error loading CSV content from url #{url}"}
    end
  end

  # Calculate combined hash
  defp concatenated_hash({:ok, %SpreadSheetData{} = spreadsheet}) do
    concatenated = Enum.reduce(spreadsheet.sheets, "", fn(ws, acc) -> ws.hash <> acc end)
    {:ok, %SpreadSheetData{spreadsheet | hash: hash(concatenated)}}
  end

  # Calculate hash for CSV content
  defp hash(content) do
    GoogleSheets.Utils.hexstring :crypto.hash(hash_func, content)
  end

  defp hash_func do
    {:ok, func} = Application.fetch_env :google_sheets, :hash_func
    func
  end
end