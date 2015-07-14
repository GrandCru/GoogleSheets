defmodule Example do
  def start(_type, _args) do
    Example.Supervisor.start_link
  end
end

defmodule Example.Supervisor do

  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, :ok, [name: __MODULE__]
  end

  def init(:ok) do
    children = []
    supervise children, strategy: :one_for_one
  end

end