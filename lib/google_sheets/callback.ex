defmodule GoogleSheets.Callback do
  use Behaviour

  # Called when the updated field of the feed was equal to last poll
  defcallback on_unchanged(id :: atom) :: any

  # Called when data has been loaded, but before persisting, can be used to change the persisted data to any format desired
  defcallback on_loaded(id :: atom, data :: GoogleSheets.SpreadSheetData.t) :: {:ok, any} | :unchanged | :error

  # Called after the data has been persisted to ETS, data is equal to the one returned from on_loaded callback
  defcallback on_saved(id :: atom, data :: any) :: any

end
