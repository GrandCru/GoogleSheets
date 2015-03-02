defmodule GoogleSheets.Callback do
  use Behaviour
  defcallback on_up_to_date(id :: atom) :: any
  defcallback on_data_loaded(id :: atom, data :: GoogleSheets.SpreadSheetData.t) :: GoogleSheets.StoredData.t
  defcallback on_data_saved(id :: atom, data :: any) :: any
end
