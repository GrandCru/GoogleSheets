defmodule GoogleSheets.Loader do

  use Pipe
  require Logger

  @doc """
  Loads all sheets in the spreadsheet published with the given access key.

  Returns a map with sheet names as keys and a value as a map with contents:
  %{
    "Sheet 1" => %{title: "Sheet 1", content: "....", sha: "sha1 hash of content"},
    "Sheet 2" => %{title: "Sheet 2", content: "....", sha: "sha1 hash of content"}
  }

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
    {:ok, parse_feed(feed, %{})}
  end

  defp parse_feed([], result), do: result
  defp parse_feed([{'{http://www.w3.org/2005/Atom}entry', _, entry} | rest], result), do: parse_feed(rest, parse_entry(entry, result))
  defp parse_feed([_node | rest], result), do: parse_feed(rest, result)

  # Parse individual worskheet entry nodes in feed
  defp parse_entry(entry, result) do
    title = find_entry_title entry
    url = find_entry_url entry
    Dict.put(result, title, url)
  end

  # Find the title of of the worksheet
  defp find_entry_title([]), do: nil
  defp find_entry_title([{'{http://www.w3.org/2005/Atom}title', [{'type', 'text'}], [title]} | _t]), do: List.to_string title
  defp find_entry_title([_h | t]), do: find_entry_title t

  # Find the url for csv content for the worksheet
  defp find_entry_url([]), do: nil
  defp find_entry_url([{'{http://www.w3.org/2005/Atom}link', [{'href', url}, {'type', 'text/csv'}, _], []} | _t]), do: List.to_string url
  defp find_entry_url([_h | t]), do: find_entry_url t

  # Load the csv content
  defp load_content({:ok, result}) do
    load_content(Dict.keys(result), result)
  end

  # Filter spreadsheet sheets and leave only those specified in the sheets list, if no list is given, don't do any filtering
  defp filter_entries({:ok, result}, [_h|_t] = sheets) do
    {filtered, _rest} = Dict.split(result, sheets)
    {:ok, filtered}
  end
  defp filter_entries({:ok, result}, _), do: {:ok, result}

  # Recursively loop throug all keys found from the feed
  defp load_content([], result), do: {:ok, result}
  defp load_content([key | rest], result) do
    case load_csv_content result[key] do
      {:ok, content} ->
        load_content(rest, Dict.put(result, key, %{title: key, content: content, hash: hash(content)}))
      {:error, msg} ->
        {:error, msg}
    end
  end

  # Fetch and parse the actual CSV content
  defp load_csv_content(url) do
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200} = response} -> {:ok, response.body}
      {:ok, response} -> {:error, "Error loading CSV content from url #{url} status: #{inspect response.status_code}"}
      {_} -> {:error, "Error loading CSV content from url #{url}"}
    end
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