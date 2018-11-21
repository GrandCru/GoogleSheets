defmodule GoogleSheets.WorkSheet do
  @moduledoc """
  Structure describing a worksheet.

  * :name   - Name of the worksheet.
  * :csv    - CSV data split into lines.
  """

  @type t :: %GoogleSheets.WorkSheet{name: String.t(), csv: [String.t()]}
  defstruct name: nil, csv: nil
end
