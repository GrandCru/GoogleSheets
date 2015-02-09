
defmodule GoogleSheets do

  use Application

  def start(_type, _args) do
    if Application.get_env :google_sheets, :start, false do
      GoogleSheets.Supervisor.start_link
    end
  end

end