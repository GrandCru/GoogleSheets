defmodule GoogleSheets.SpreadSheetData do
  defstruct hash: nil, sheets: []
  @type t :: %GoogleSheets.SpreadSheetData{hash: String.t, sheets: [GoogleSheets.WorkSheetData.t]}
end

defmodule GoogleSheets.WorkSheetData do
  defstruct name: nil, hash: nil, csv: nil
  @type t :: %GoogleSheets.WorkSheetData{name: String.t, hash: String.t, csv: String.t}
end

defmodule GoogleSheets.Updater.Config do
  defstruct key: nil, sheets: [], delay: 0, hash_func: nil, ets_table: nil, ets_key: nil, transform: nil, notify: nil
  @type t :: %GoogleSheets.Updater.Config{key: String.t, sheets: [String.t], delay: integer, hash_func: atom, ets_table: atom, ets_key: atom, transform: module, notify: module}

  def new_from_app_config do
    %GoogleSheets.Updater.Config{
      key: fetch_env(:key),
      sheets: fetch_env(:sheets),
      delay: fetch_env(:delay),
      hash_func: fetch_env(:hash_func),
      ets_table: fetch_env(:ets_table),
      ets_key: fetch_env(:ets_key),
      transform: fetch_env(:transform),
      notify: fetch_env(:notify)
    }
  end

  defp fetch_env(key) do
    {:ok, value} = Application.fetch_env :google_sheets, key
    value
  end

end