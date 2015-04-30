
defmodule GoogleSheets do

  use Application
  require Logger

  @moduledoc false

  @doc false
  def start(_type, _args) do
    GoogleSheets.Supervisor.start_link
  end

  #
  # Library API
  #
  defdelegate update_config(spreadsheet_id), to: GoogleSheets.Updater
  defdelegate update_config(spreadsheet_id, timeout), to: GoogleSheets.Updater
  defdelegate latest_key(spreadsheet_id), to: GoogleSheets.Utils
  defdelegate get({id, key}), to: GoogleSheets.Utils
  defdelegate await_key(id), to: GoogleSheets.Utils
  defdelegate await_key(id, timeout), to: GoogleSheets.Utils

end