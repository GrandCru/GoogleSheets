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

config :google_sheets,
  ets_table: :google_sheets,
  supervisor_max_restarts: 3,
  supervisor_max_seconds: 5,
  spreadsheets: [
    [
      id: :spreadsheet,
      sheets: ["KeyValue"],
      poll_delay_seconds: 120,
      callback_module: nil,
      loader_init: [
        module: GoogleSheets.Loader.FileSystem,
        dir: "priv/data"
      ],
      loader_poll: [
        module: GoogleSheets.Loader.Docs,
        url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
      ]
    ]
  ]

if File.exists? Path.expand("#{Mix.env}.exs", __DIR__) do
  import_config "#{Mix.env}.exs"
end
