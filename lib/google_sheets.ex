
defmodule GoogleSheets do

  use Application

  def start(_type, _args) do
    GoogleSheets.Supervisor.start_link
  end

end