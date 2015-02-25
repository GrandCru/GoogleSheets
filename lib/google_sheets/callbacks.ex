defmodule GoogleSheets.Callback do
  use Behaviour
  defcallback on_data_loaded(id :: atom, data :: GoogleSheets.SpreadSheetData.t) :: any
  defcallback on_data_saved(id :: atom) :: any
end
