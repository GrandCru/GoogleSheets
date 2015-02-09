# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configuration options:
# start:    true | false, whether the GoogleSheets application is started or not.
#           (You can still use directly the loader functionality)
# key:      The publish key for the google sheet to load.
# sheets:   List of sheets to export, if nil or empty list, all sheets are fetched.
# delay:    Delay in seconds after a succesful fetch from Google Sheets.
config :google_sheets,
  start:      true,
  key:        "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs",
  sheets:     ["KeyValue", "KeyTable", "KeyIndexTable"],
  delay:      30,
  hash_func:  :md5

