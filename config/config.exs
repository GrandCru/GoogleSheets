# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  console: [
    format: "$time [$level]$levelpad $message $metadata\n",
    level: :debug,
    metadata: [:module, :line],
  ],
  utc_log: true

# Example configuration options, see README.md for more information
config :google_sheets,
  ets_table: :google_sheets,
  supervisor_max_restarts: 3,
  supervisor_max_seconds: 5,
  spreadsheets: [
    [
      id: :multiple_worksheets,
      sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      poll_delay_seconds: 120,
      callback_module: nil,
      loader_init: [
        module: GoogleSheets.Loader.FileSystem,
        src: "priv/data"
      ],
      loader_poll: [
        module: GoogleSheets.Loader.Docs,
        src: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
      ]
    ],
    [
      id: :single_worksheet,
      sheets: ["KeyValue"],
      poll_delay_seconds: 120,
      callback_module: nil,
      loader_init: [
        module: GoogleSheets.Loader.FileSystem,
        src: "priv/data"
      ],
      loader_poll: [
        module: GoogleSheets.Loader.Docs,
        src: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
      ]
    ]
  ]
