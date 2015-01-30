# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configuration options:
# key: The key for google sheet to load. If nil, the updater app won't do anything
# sheets: List of sheets to export, if nil or empty, all sheets are fetched.
# update_intevera_ms: How often is the worksheet polled, if set to 0, the updater will run only once.
config :google_sheets,
  key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
  sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
  update_interval_ms: 30000

