
defmodule GoogleSheets.Supervisor do
  use Supervisor

  require Keyword

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, ets_table} = Application.fetch_env :google_sheets, :ets_table
    {:ok, spreadsheets} = Application.fetch_env :google_sheets, :spreadsheets
    {:ok, max_restarts} = Application.fetch_env :google_sheets, :max_restarts
    {:ok, max_seconds} = Application.fetch_env :google_sheets, :max_seconds

    # ETS table is created here, so that if the updater process dies, the table is not lost.
    # Must set the permission to public, so that the GoogleSheets.Updater can write,
    # to the table, even if it's not the owning process.
    :ets.new ets_table, [:set, :named_table, :public]

    supervise(create_children(spreadsheets, []), strategy: :one_for_one, max_restarts: max_restarts, max_seconds: max_seconds)
  end

  # Create a children for each configured worksheet
  defp create_children([], children), do: children
  defp create_children([spreadsheet | rest], children) do
    valid_config(spreadsheet)
    create_children rest, [worker(GoogleSheets.Updater, [spreadsheet], id: spreadsheet[:id], restart: :permanent) | children]
  end

  # Just to capture errors in application configuration early
  def valid_config(spreadsheet) do
    true = Keyword.has_key?(spreadsheet, :id)
    true = is_atom(spreadsheet[:id])

    true = Keyword.has_key?(spreadsheet, :key)
    true = String.length(String.strip(spreadsheet[:key])) > 0

    [_h | _t] = spreadsheet[:sheets]

    true = Keyword.has_key?(spreadsheet, :delay)
    true = is_integer(spreadsheet[:delay])

    true = Keyword.has_key?(spreadsheet, :callback)
  end

end