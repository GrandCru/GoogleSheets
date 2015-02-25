defmodule GoogleSheets.Callback do
  use Behaviour
  defcallback on_data_loaded(data :: GoogleSheets.SpreadSheetData.t) :: any
  defcallback on_data_saved() :: any
end
