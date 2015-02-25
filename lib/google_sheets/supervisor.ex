
defmodule GoogleSheets.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    # ETS table is created here, so that if the updater process dies, the table is not lost.
    # Must set the permission to public, so that the GoogleSheets.Updater can write,
    # to the table, even if it's not the owning process.

    config = GoogleSheets.Updater.Config.from_env
    if config.delay >= 0 do
      :ets.new config.ets_table, [:set, :named_table, :public]
      children = [ worker(GoogleSheets.Updater, [config, [name: GoogleSheets.Updater]]) ]
      supervise(children, strategy: :one_for_one)
    else
      supervise([], strategy: :one_for_one)
    end
  end

end