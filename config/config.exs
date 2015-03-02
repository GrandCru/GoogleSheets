# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Example configuration options, see README.md for more information

config :google_sheets,
  spreadsheets: [
    [
      id: :worksheet_multiple,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      included: ["KeyValue", "KeyTable", "KeyIndexTable"],
      excluded: [],
      delay: 10,
      callback: nil
    ],
    [
      id: :worksheet_single,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      included: ["KeyValue"],
      excluded: [],
      delay: 10,
      callback: nil
    ]
  ],
  ets_table: :google_sheets

if Mix.env == :test do
  config :google_sheets,
    spreadsheets: [],
    ets_table: :google_sheets
end