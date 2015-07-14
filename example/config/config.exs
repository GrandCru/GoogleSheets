use Mix.Config


config :google_sheets,
  ets_table: :example,
  supervisor_max_restarts: 3,
  supervisor_max_seconds: 5,
  spreadsheets: [
    [
      id: :key_value,
      sheets: ["KeyValue"],
      callback: Example.KeyValueParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 300,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ],
    [
      id: :key_table,
      sheets: ["KeyTable"],
      callback: Example.KeyTableParser,
      loader: GoogleSheets.Loader.Docs,
      poll_delay_seconds: 300,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
    ]
  ]

