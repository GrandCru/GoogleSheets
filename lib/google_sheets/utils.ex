defmodule GoogleSheets.Utils do

  @moduledoc """
  Generic utilities.
  """

  # 5 second timeout before failing the await function
  @await_delay 100
  @await_timeout 5_000

  @doc """
  Return key for the latest entry stored for the Spreadsheet identified by id.
  """
  def latest_key(id) when is_atom(id) do
    [{_lookup_key, _updated, key}] = :ets.lookup ets_table, {id, :latest}
    {id, key}
  end

  @doc """
  Returns data for a stored Spreadsheet matching the given {id, key} tuple.
  """
  def get({id, key}) when is_atom(id) do
    [{_lookup_key, _updated, data}] = :ets.lookup ets_table, {id, key}
    data
  end

  @doc """
  Waits until an ETS entry has been written for the given id and returns the key specifying the latest version.
  """
  def await_key(id, timeout \\ @await_timeout) do
    task = Task.async(fn -> try_get(id, timeout) end)
    Task.await task, timeout
  end

  @doc """
  Returns the ETS table name where data is stored.
  """
  def ets_table do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    ets_table
  end

  @doc """
  Convert a 128 bit binary value into hex string (md5 hash)
  """
  def hexstring(<<x::size(128)>>), do: to_string(hd(:io_lib.format("~32.16.0b",  [x])))

  @doc """
  Convert a 160 bit binary value into hex string (sha1 hash)
  """
  def hexstring(<<x::size(160)>>), do: to_string(hd(:io_lib.format("~40.16.0b",  [x])))

  @doc """
  Convert a 256 bit binary value into hex string (sha256 hash)
  """
  def hexstring(<<x::size(256)>>), do: to_string(hd(:io_lib.format("~64.16.0b",  [x])))

  @doc """
  Convert a 512 bit binary value into hex string (sha512 hash)
  """
  def hexstring(<<x::size(512)>>), do: to_string(hd(:io_lib.format("~128.16.0b", [x])))

  #
  # Private helpers
  #

  # Tries to get the latest entry from database
  defp try_get(_id, 0), do: {:error, :timeout}
  defp try_get(id, timeout) do
    case :ets.lookup ets_table, {id, :latest} do
      [] ->
        :timer.sleep @await_delay
        try_get id, max(0, timeout - @await_delay)
      [{_lookup_key, _version, key}] ->
        {id, key}
    end
  end

end
