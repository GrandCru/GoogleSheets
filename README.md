# Google Sheets 

[![Build Status](https://travis-ci.org/GrandCru/GoogleSheets.svg?branch=master)](https://travis-ci.org/GrandCru/GoogleSheets)
[![Hex.pm Version](http://img.shields.io/hexpm/v/google_sheets.svg?style=flat)](https://hex.pm/packages/google_sheets)

`Google Sheets` is an Elixir library for fetching Google spreadsheet in `CSV` format. It can be used as a command line tool to save loaded CSV files into a local directory, but the main application is to monitor changes in a spreadsheet and store them into ETS table, where the host application can access it.

## Quick start

```elixir

# Make sure you have published spreadsheet to be accessible without 
# authorization, see Publishing Google spreadsheet chapter for instructions.

# In your mix.exs file
defp deps do
  [ {:google_sheets, "~> 1.1"} ]
end
def application do
  [applications: [:logger, :google_sheets]]
end

# In your `config/config.exs` file:
config :google_sheets,
  spreadsheets:
  [
    [    
      id: :config,
      parser: MyConfigParser, # Or nil, if not implementing parser
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/" <>
           "19HcQV5Z-uTXaVxjm2jVJNGNFv0pzA_cgdBTWMe4a77Y/public/basic"
    ]
  ]

# Optionally write a module implementing GoogleSheets.Parser behaviour.
# The purpose of this is to allow converting raw CSV data into application
# specific data format.
defmodule MyConfigParser do
  @behaviour GoogleSheets.Parser
  def parse(_id, worksheets) do
    data = convert_raw_csv_to_structs worksheets
    {:ok, data}
  end

  defp convert_raw_csv_to_structs(worksheets), do: ....
end

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

# Before running your application you must first load initial data
# into local directory. This is required, so that the application always
# has a known good configuration before trying to load data directly from
# google.

mix gs.fetch -u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic -d priv/data

```

## How it works

When application starts, the [supervisor](lib/google_sheets/supervisor.ex) creates an `ETS` table named `:google_sheets` and starts an [updater process](lib/google_sheets/updater.ex) for each configured spreadsheet. Each updater process monitors one spreadsheet for changes by polling it. If changes are noticed, it will load the new data, pass it into parser and store updated data into ETS table.

During the init phase data is CSV data is loaded from files in local filesystem. Therefore you must fetch data using the gs.fetch mix task to preload data. This requirement means that application can always succesfully start - even if Google services are down! 

### Using the library

After the application has started, you can query loaded data using the public API defined in [GoogleSheets module](doc/GoogleSheets.html).

### Configuration

* __:spreadsheets__ - A list of configurations for each spreadsheet to monitor.

Each __:spreadsheets__ list entry is a keyword list:

* __:id__ - Atom used as the name of the updater process and as part of key when saving data into ETS table.
* __:sheets__ - List of worksheet names to load. If empty, all worksheets in spreadsheet are loaded.
* __:poll_delay_seconds__ - Delay between updates. If 0, only the init phase loading is done. Default is 30 seconds.
* __:parser__ - Module implementing GoogleSheets.Parser behaviour or nil. If specified, the parse/2 method of the module is called after CSV data has been loaded, but before a new entry is stored into ETS table.
* __:loader__ - Module implementing [GoogleSheets.Loader](lib/google_sheets/loader.ex) behaviour. Default is [GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) which loads data form a google spreadsheet.
* __:url__ - URL of the Google spreadsheet to load.
* __:dir__ - Local directory relative to application root where CSV files fetched before are located.

## Publishing Google Spreadsheet

The default way to share a spreadsheet using Google Sheets API is to use `OAuth`, but afaik there is no way to get a permanent `OAuth` token to use with a server. Therefore we must make the spreadsheet public to allow access from a server.

To make things worse, you must both publish the worksheet to web (this allows fetching the worksheet feed and find individual sheet URLs) and share the worksheet (this allows us to fetch the actual CSV content).

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](/docs/share_link.png)

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](/docs/publish_to_web.png)

## Mix gs.fetch task

The mix task [gs.fetch](lib/mix/task/gs.fetch.ex) loads a Google spreadsheet and saves worksheets in specified directory. If no parameters are given, it fetches all spreadsheets specified in the applications :google_sheets configuration and writes data into corresponding directory. You can also provide `-u` and `-d` params to explicitly load a spreadsheet.

```
mix gs.fetch
-u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic 
-d priv/data
```

## More information

* [Google Sheets API documentation](https://developers.google.com/google-apps/spreadsheets/) - More information about the structure of atom feed and about the public vs private visibility.

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.
