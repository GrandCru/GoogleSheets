# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Example configuration options:
# As usual, this configuration file is not parsed, if you use this application as
# dependency. So to enable this packaged, you must configure

# start_app:  true | false, whether the :google_sheets application is started or not.
# key:        The publish key for the google sheet to load.
# sheets:     List of sheets to export, if nil or empty list, all sheets are fetched.
# delay:      Dlay in seconds after a succesful fetch from Google Sheets.
# hash_func   What :crypto.hash algorithms to use, supported, :md5, :sha, :sha256, :sha512
# ets_table   Name of the ets table where to store loaded sheet.
# ets_key     Name of the key where the loaded key is stored.

config :google_sheets,
  start_app:    true,
  key:          "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
  sheets:       ["KeyValue", "KeyTable", "KeyIndexTable"],
  delay:        30,
  hash_func:    :md5,
  ets_table:    :google_sheets,
  ets_key:      :data
