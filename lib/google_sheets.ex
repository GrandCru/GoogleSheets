
defmodule GoogleSheets do

  use Application
  require Logger

  def start(_type, _args) do
    if Application.get_env(:google_sheets, :delay, -1) >= 0 do
      GoogleSheets.Supervisor.start_link
    end
  end

end