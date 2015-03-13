# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Example configuration options, see README.md for more information

config :google_sheets,
  ets_table: :google_sheets,
  max_restarts: 3,
  max_seconds: 5,
  spreadsheets: [
    [
      id: :multiple_worksheets,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      delay: 10,
      callback: nil
    ],
    [
      id: :single_worksheet,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      sheets: ["KeyValue"],
      delay: 10,
      callback: nil
    ]
  ]

if Mix.env == :test do
  config :google_sheets,
    spreadsheets: [],
    ets_table: :google_sheets
end