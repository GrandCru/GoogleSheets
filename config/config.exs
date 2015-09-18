# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :google_sheets, spreadsheets: [
  [
    id: :keyvalue,
    sheets: ["KeyValue"],
    parser: nil,
    loader: GoogleSheets.Loader.Docs,
    poll_delay_seconds: 1,
    dir: "priv/data",
    url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
  ],
  [
    id: :multiple,
    sheets: ["KeyValue", "KeyTable"],
    parser: nil,
    loader: GoogleSheets.Loader.Docs,
    poll_delay_seconds: 1,
    dir: "priv/data",
    url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
  ]
]

config :ex_doc, :markdown_processor, ExDoc.Markdown.Pandoc
