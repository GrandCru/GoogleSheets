
defmodule GoogleSheets do

  use Application
  require Logger

  @moduledoc false

  @doc false
  def start(_type, _args) do
    GoogleSheets.Supervisor.start_link
  end

end