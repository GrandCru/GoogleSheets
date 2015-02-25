
defmodule GoogleSheets.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    {:ok, spreadsheets} = Application.fetch_env :google_sheets, :spreadsheets

    # ETS table is created here, so that if the updater process dies, the table is not lost.
    # Must set the permission to public, so that the GoogleSheets.Updater can write,
    # to the table, even if it's not the owning process.
    :ets.new ets_table, [:set, :named_table, :public]

    supervise(create_children(spreadsheets, []), strategy: :one_for_one)
  end

  # Create a children for each configured worksheet
  defp create_children([], children), do: children
  defp create_children([spreadsheet | rest], children) do
    create_children rest, [worker(GoogleSheets.Updater, [spreadsheet], id: spreadsheet[:id]) | children]
  end

end