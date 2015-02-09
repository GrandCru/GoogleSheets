defmodule HexStringTest do

  use ExUnit.Case, async: true

  test "Test md5 to hex conversion" do
    hash = :crypto.hash :md5, "The quick brown fox jumps over the lazy dog"
    assert GoogleSheets.Utils.hexstring(hash) == "9e107d9d372bb6826bd81d3542a419d6"
  end

  test "Test sha1 to hex conversion" do
    hash = :crypto.hash(:sha, "The quick brown fox jumps over the lazy dog")
    assert GoogleSheets.Utils.hexstring(hash) == "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"
  end

  test "Test sha256 to hex conversion" do
    hash = :crypto.hash(:sha256, "The quick brown fox jumps over the lazy dog")
    assert GoogleSheets.Utils.hexstring(hash) == "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
  end

  test "Test sha512 to hex conversion" do
    hash = :crypto.hash(:sha512, "The quick brown fox jumps over the lazy dog")
    assert GoogleSheets.Utils.hexstring(hash) == "07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6"
  end

end