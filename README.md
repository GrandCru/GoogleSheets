# Google Sheets 

`Google Sheets` is an Elixir library for fetching Google spreadsheet in `CSV` format. It supports both saving a spreadsheet into a local directory as well as monitoring changes in a spreadsheet during runtime. The loaded spreadsheet is stored in `ETS` table where the application can access it.

[![Hex.pm Version](http://img.shields.io/hexpm/v/google_sheets.svg?style=flat)](https://hex.pm/packages/google_sheets)

## Quick start

```elixir

# Make sure you have made your spreadsheet readable to without authorization,
# see Publishing Google spreadsheet chapter on how to do it.

# Add dependency to GoogleSheets in your `mix.exs` file:
defp deps do
  [ {:google_sheets, "~> 1.0"} ]
end

# In your `config/config.exs` file:
config :google_sheets,
  spreadsheets:
  [
    [    
      id: :config,
      parser: MyConfigParser,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/" <>
           "19HcQV5Z-uTXaVxjm2jVJNGNFv0pzA_cgdBTWMe4a77Y/public/basic"
    ]
  ]

# Optionally write a module implementing GoogleSheets.Parser behaviour for
# converting raw CSV data into useable data structures for your application.
defmodule MyConfigParser do
  @behaviour GoogleSheets.Parser
  def parse(_id, worksheets) do
    # Actual conversion using something like ex_csv library 
    # left as an exercise for the reader.
    converted = parse_worksheets worksheets
    {:ok, converted}
  end
end

# In your application code
defmodule MyApp do
  def func do
    {:ok, version_key, data} = GoogleSheets.latest :config
    {version_key, data} = GoogleSheets.latest :config

    {:ok, version_key} = GoogleSheets.latest_key :config
    version_key = GoogleSheets.latest_key! :config

    # With a previously queried version_key
    {:ok, data} = GoogleSheets.fetch version_key
    data = GoogleSheets.fetch! version_key
  end
end

# The library requires that known good data is present locally
# through filesystem at the application start phase. 
# The mix task gs.fetch uses the :google_sheets configuration to fetch CSV
# data and saves them locally.
mix gs.fetch

```

## How it works

When application starts, the [supervisor](lib/google_sheets/supervisor.ex) creates an `ETS` table named `:google_sheets` and starts an [updater process](lib/google_sheets/updater.ex) for each configured spreadsheet.

During the updater process init phase, CSV data is loaded from the local filesystem and passed to the configured :parser module before storing data in ETS table.

After that the udpater process enters in loop, where it periodically fetches spreadsheet data, checks if it has changed, calls the :parser module and stores a new version into ETS table, if the monitored spreadsheet has changed.

## Using the library

After the application has started, you can access the loaded data using the [GoogleSheets.fetch and GoogleSheets.latest_key](doc/GoogleSheets.html) functions.

### ETS storage

Each time a change is noticed by an updater process, a new version of the data is stored in ETS table named `:google_sheets` with an unique version_key. In addition for each spreadsheet, a special entry {:spreadsheet_id, :latest} contains the key for the latest version of a spreadsheet stored.

### Multiple spreadsheets

Since the :spreadsheets configuration parameter is a list, you can monitor as many spreadsheets as your application requires.

### Configuration

* __:spreadsheets__ - A list of configurations for each spreadsheet to monitor.

Each __:spreadsheets__ list entry is a keyword list with parameters how to monitor a single spreadsheet:

* __:id__ - Atom used as the name of the updater process and as part of key when saving data into ETS table.
* __:sheets__ - List of worksheet names to load. If empty, all worksheets in spreadsheet are loaded.
* __:poll_delay_seconds__ - Delay between updates. If 0, only the init phase loading is done. Default is 30.
* __:parser__ - Module implementing GoogleSheets.Parser behaviour. If implemented, the parse/2 method of the module is called after CSV data has been loaded, but before a new entry is stored into ETS table.
* __:loader__ - Module responsible for loading data after the inital loading from fileystem. The module must be implement [GoogleSheets.Loader](lib/google_sheets/loader.ex) behaviour. Default is [GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) which loads data form a google spreadsheet pointed by :url parameter.
* __:url__ - URL of the google spreadsheet to load.
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

## Triggering manually an update

To trigger an check for changes in spreadsheet, you can call the GoogleSheets.Update/1 function with spreadsheet_id as parameter. This can be useful when you have just changed a spreadsheet and wan't the updates to be immediately available. For example, you can expose a http API which will then call this function.

## More information

* [Google Sheets API documentation](https://developers.google.com/google-apps/spreadsheets/) - More information about the structure of atom feed and about the public vs private visibility.

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.
