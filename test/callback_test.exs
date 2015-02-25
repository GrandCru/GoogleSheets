defmodule CallbackTest do
  use ExUnit.Case
  require Logger

  @test_pid nil

  @behaviour GoogleSheets.Callback
  def on_loaded(data) do
  end

  def on_saved() do
  end

  test "Test updater process" do
    @test_pid
    config = GoogleSheets.Updater.Config.from_env
    config = %{config | callback: MockCallback, delay: 0}
  end

end

