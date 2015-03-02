# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Example configuration options:
# As usual, this configuration file is not parsed, if you use this application as
# dependency. So to enable this packaged, you must configure

# delay:      How many seconds to wait after succesfull poll to start a new try.
#             If updater fails, a new try is started after 1 second delay.
#             If negative, the updater process is not started.
# key:        The publish key for the google sheet to load.
# sheets:     List of sheets to export, if nil or empty list, all sheets are fetched.
# hash_func   What :crypto.hash algorithms to use, supported, :md5, :sha, :sha256, :sha512
# ets_table   Name of the ets table where to store loaded sheet.
# ets_key     Name of the key where the loaded key is stored.
# transform   Module implementing GoogleSheets.Transform behaviour. This module
#             can be used to convert the raw CSV data to host application specific
#             format. For example, converting CSV to a Map.
# notify      Module impelmenting GoogleSheets.Notify behaviour.

config :google_sheets,
  spreadsheets: [
    [
      id: :worksheet_multiple,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      included_sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      delay: 10,
      callback: nil
    ],
    [
      id: :worksheet_single,
      key: "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
      included_sheets: ["KeyValue"],
      delay: 10,
      callback: nil
    ]
  ],
  hash_func: :md5,
  ets_table: :google_sheets
