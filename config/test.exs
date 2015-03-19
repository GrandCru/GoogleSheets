use Mix.Config

# Example configuration used to run tests, see README.md for more information
config :google_sheets,
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
