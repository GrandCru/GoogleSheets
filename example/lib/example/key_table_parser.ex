defmodule Example.KeyTableParser do

  require Logger

  @behaviour GoogleSheets.Callback

  # Converts the "KeyTable" sheet into a map using ex_csv library
  def on_loaded(previous_version, %GoogleSheets.SpreadSheetData{} = spreadsheet) do
    sheet = hd spreadsheet.sheets
    data = sheet.csv
    |> ExCsv.parse!
    |> ExCsv.with_headings
    |> ExCsv.as(Example.KeyTable, %{"Id" => :id, "WeaponClass" => :weapon_class, "ArmorClass" => :armor_class})
    |> Enum.to_list
    data
  end

end

defmodule Example.KeyTable do
  defstruct id: nil, weapon_class: nil, armor_class: nil
end