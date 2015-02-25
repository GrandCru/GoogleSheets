defmodule GoogleSheets.Callback do
  use Behaviour
  defcallback on_loaded(data :: GoogleSheets.SpreadSheetData.t) :: any
  defcallback on_saved() :: any
end
