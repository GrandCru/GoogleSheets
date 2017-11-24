# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :google_sheets, spreadsheets: [
  config: [
    sheets: ["KeyValue"],
    ignored_sheets: [],
    parser: nil,
    loader: GoogleSheets.Loader.Docs,
    poll_delay_seconds: 360,
    dir: "priv/data",
    url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
  ],
  multiple: [
    sheets: ["KeyValue", "KeyTable", "Ignored"],
    ignored_sheets: ["Ignored"],
    parser: nil,
    loader: GoogleSheets.Loader.Docs,
    poll_delay_seconds: 360,
    dir: {:google_sheets, "priv/data"},
    url: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
  ]
]

# TSL/SSL protocol selection is now fixed in OTP-13753, see http://erlang.org/download/OTP-19.0.3.README
# config :ssl, protocol_version: :"tlsv1.2"

if Mix.env == :dev do
  config :ex_doc, :markdown_processor, ExDoc.Markdown.Pandoc
end

# We can override specific variables depending on mix env since the configurations are deeply merged with later ones
# overriding values. For example in prod environment we might wish to set the polling delay to 0, so that we never
# load anything except the deployed configuration.
if Mix.env == :prod do
  config :google_sheets, spreadsheets: [
    config: [poll_delay_seconds: 0],
    multiple: [poll_delay_seconds: 0]
  ]
end
