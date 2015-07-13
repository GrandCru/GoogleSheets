
defmodule GoogleSheets.Supervisor do

  @moduledoc """
  Supervisor for the application, launches a process for each spreadsheet configured for polling.
  """

  use Supervisor
  require Keyword

  # See http://elixir-lang.org/docs/v1.0/elixir/Supervisor.Spec.html#supervise/2
  @max_restarts 3
  @max_seconds 5

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc false
  def init([]) do
    ets_table = Application.get_env :google_sheets, :ets_table, :google_sheets
    spreadsheets = Application.get_env :google_sheets, :spreadsheets, []
    max_restarts = Application.get_env :google_sheets, :supervisor_max_restarts, @max_restarts
    max_seconds = Application.get_env :google_sheets, :supervisor_max_seconds, @max_seconds

    # ETS table is created here, so that if the updater process dies, the table is not lost.
    # Must set the permission to public, so that the GoogleSheets.Updater can write,
    # to the table, even if it's not the owning process.
    :ets.new ets_table, [:set, :named_table, :public]

    supervise(create_children(spreadsheets, []), strategy: :one_for_one, max_restarts: max_restarts, max_seconds: max_seconds)
  end

  # Create a children for each configured spreadsheet
  defp create_children([], children), do: children
  defp create_children([spreadsheet | rest], children) do
    id = Keyword.fetch! spreadsheet, :id
    create_children rest, [worker(GoogleSheets.Updater, [spreadsheet], [id: id, restart: :permanent]) | children]
  end

end