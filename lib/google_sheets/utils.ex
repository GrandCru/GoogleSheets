defmodule GoogleSheets.Utils do

  # 5 second timeout before failing the await function
  @await_delay 100
  @await_timeout 5_000

  # Get latest entry for the given key
  def get(id) when is_atom(id) do
    [{_lookup_key, _key, _updated, data}] = :ets.lookup ets_table, {id, :latest}
    data
  end

  def get(id, key) when is_atom(id) do
    [{_lookup_key, updated, data}] = :ets.lookup ets_table, {id, key}
    data
  end

  # Wait that ETS table has an entry available
  def await(id) do
    await(id, @await_timeout)
  end
  def await(id, delay) do
    task = Task.async(fn -> try_get(id, delay) end)
    Task.await task, delay
  end

  def ets_table do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    ets_table
  end

  # Converts a binary value to hex string (md5 = 128 bits, sha1 = 160 bits, sha256 = 256 bits and sha512 = 512 bits)
  def hexstring(<<x::size(128)>>), do: to_string(hd(:io_lib.format("~32.16.0b",  [x])))
  def hexstring(<<x::size(160)>>), do: to_string(hd(:io_lib.format("~40.16.0b",  [x])))
  def hexstring(<<x::size(256)>>), do: to_string(hd(:io_lib.format("~64.16.0b",  [x])))
  def hexstring(<<x::size(512)>>), do: to_string(hd(:io_lib.format("~128.16.0b", [x])))

  #
  # Private helpers
  #

  # Tries to get the latest entry from database
  defp try_get(id, 0), do: {:error, :timeout}
  defp try_get(id, timeout) do
    case :ets.lookup ets_table, {id, :latest} do
      [] ->
        :timer.sleep @await_delay
        try_get id, max(0, timeout - @await_delay)
      [{_lookup_key, _key, _last_updated, data}] ->
        data
    end
  end

end
