defmodule GoogleSheets.Notify do
  use Behaviour
  defcallback on_update() :: any
end

defmodule GoogleSheets.Transform do
  use Behaviour
  defcallback do_transform(data :: GoogleSheets.SpreadSheetData.t) :: any
end