# Google Sheets 

[![Build Status](https://travis-ci.org/GrandCru/GoogleSheets.svg?branch=master)](https://travis-ci.org/GrandCru/GoogleSheets)
[![Hex.pm Version](http://img.shields.io/hexpm/v/google_sheets.svg?style=flat)](https://hex.pm/packages/google_sheets)

`Google Sheets` is an OTP application for fetching Google spreadsheet in CSV format, optionally parsing and converting into application specific data structures and storing each loaded version into ETS table with unique key. The host application can query latest or specific version of stored data using provided API.

Main use case for the library is a game server, where game configuration is edited in a Google spreadsheet. By polling changes and using the latest version for each new client connection, it is possible to rapidly tweak configuration without needing to deploy or restart server.

The library can also be used as a command line tool to fetch spreadsheet data and save it into local directory.

## Quick start

```elixir

# Make sure you have published spreadsheet to be accessible without 
# authorization, see Publishing Google spreadsheet for instructions.

# In your mix.exs file
defp deps do
  [ {:google_sheets, "~> 2.0"} ]
end
def application do
  [applications: [:logger, :google_sheets]]
end

# In your `config/config.exs` file:
config :google_sheets, spreadsheets: [
  config: [
    dir: "priv/data",
    url: "https://spreadsheets.google.com/feeds/worksheets/" <>
          "19HcQV5Z-uTXaVxjm2jVJNGNFv0pzA_cgdBTWMe4a77Y/public/basic"
  ]
]

# In your application code
defmodule MyApp do
  def func do
    # Get the latest version and data for :config spreadsheet
    {:ok, version, data} = GoogleSheets.latest :config
    {version, data} = GoogleSheets.latest! :config

    # Get just the data for latest :config spreadsheet
    {:ok, data} = GoogleSheets.latest_data :config
    data = GoogleSheets.latest_data! :config

    # Get just the version for latest :config spreadsheet 
    {:ok, version} = GoogleSheets.latest_version :config
    version = GoogleSheets.latest_version! :config

    # Use fetch to get specific version
    {:ok, data} = GoogleSheets.fetch version
    data = GoogleSheets.fetch! version
  end
end

# The library expects that initial data is loaded from a local directory.
# Therefore before starting your application, use the mix gs.fetch task
# to save data into local directory.
mix gs.fetch -u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic -d priv/data

```


## How it works

When the application starts, the [supervisor](lib/google_sheets/supervisor.ex) creates an `ETS` table named `:google_sheets` and starts an [updater process](lib/google_sheets/updater.ex) for each configured spreadsheet. Each updater process monitors one spreadsheet and if changes are noticed, it will load the new data, pass it into parser and store updated data into ETS table.

During genserver init callback CSV data is loaded from local file system. Therefore you must fetch data using the gs.fetch mix task to fetch data before starting application. This requirement means that application can always successfully start - even if Google services are down! 

### Using the library

After the application has started, you can query loaded data using the public API defined in [GoogleSheets module](lib/google_sheets.ex).

### Configuration

* __:spreadsheets__ - A keyword list of spreadsheet configurations. The key is an atom uniquely identifying a spreadsheet.

Each __:spreadsheets__ list entry is a keyword list:

* __:sheets__ - List of worksheet names to load. If empty, all worksheets in spreadsheet are loaded.
* __:poll_delay_seconds__ - How often changes the monitored spreadsheet are polled. If 0, no polling is done. If not defined, the default is 30 seconds.
* __:loader__ - Module implementing [GoogleSheets.Loader](lib/google_sheets/loader.ex) behavior. If nil, the default is to use [GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) which loads data form a google spreadsheet. In this case the :url parameter must be specified.
* __:parser__ - Module implementing [GoogleSheets.Parser](lib/google_sheets/parser.ex) behavior. If nil, the raw CSV data is stored into ETS table.
* __:url__ - URL of the Google spreadsheet to load.
* __:dir__ - Local directory relative to application root where CSV files fetched before are located. For example priv/data

For a complete example configuration, see [config.exs](config/config.exs). 

## Publishing Google Spreadsheet

The default way to share a spreadsheet using Google Sheets API is to use `OAuth`. It might be possible to use [two legged OAuth](https://developers.google.com/identity/protocols/OAuth2ServiceAccount) to support serverside authentication, but no effort has been spent investigating whether this works or not. Therefore it is required that the spreadsheet has been publicly published.

For the library to work correctly, spreadsheet must published to web and shared. Publishing allows fetching worksheet feed containing URLs to individual worksheets and sharing allows us to access the actual CSV content.

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](https://raw.githubusercontent.com/GrandCru/GoogleSheets/master/docs/publish_to_web.png)

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](https://raw.githubusercontent.com/GrandCru/GoogleSheets/master/docs/share_link.png)

## Mix gs.fetch task

The mix task [gs.fetch](lib/mix/task/gs.fetch.ex) loads a Google spreadsheet and saves worksheets in specified directory. If no parameters are given, it fetches all spreadsheets specified in the applications :google_sheets configuration and writes data into corresponding directory. You can also provide `-u` and `-d` arguments to manually specify parameters.

```
mix gs.fetch \
-u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic \
-d priv/data
```

## More information

* [Google Sheets API documentation](https://developers.google.com/google-apps/spreadsheets/) - More information about the structure of atom feed and about the public vs private visibility.

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.
