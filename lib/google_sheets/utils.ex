defmodule GoogleSheets.Utils do

  @moduledoc """
  Helper functions used by other modules in this library.
  """

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

end
