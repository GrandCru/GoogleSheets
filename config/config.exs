# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Example configuration options, see README.md for more information
config :google_sheets,
  ets_table: :google_sheets,
  supervisor_max_restarts: 3,
  supervisor_max_seconds: 5,
  spreadsheets: [
    [
      id: :multiple_worksheets,
      sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      poll_delay_seconds: 10,
      callback_module: nil,
      loader_init: [module: GoogleSheets.Loader.FileSystem, dir: "priv/data"],
      loader_poll: [module: GoogleSheets.Loader.Docs, key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"]
    ],
    [
      id: :single_worksheet,
      sheets: ["KeyValue"],
      poll_delay_seconds: 10,
      callback_module: nil,
      loader_init: [module: GoogleSheets.Loader.FileSystem, dir: "priv/data"],
      loader_poll: [module: GoogleSheets.Loader.Docs, key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs"]
    ]
  ]
