# Google Sheets 

`Google Sheets` is an Elixir library for fetching Google spreadsheet in `CSV` format. It supports both fetching and saving a spreadsheet into a local directory as well as monitoring changes in a spreadsheet during applications runtime. The loaded (and potentially parsed and transformed) spreadsheet is stored in `ETS` table where the application can access it.

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
           "19HcQV5Z-uTXaVxjm2jVJNGNFv0pzA_cgdBTWMe4a77Y/public/basic",
    ]
  ]

# Optionally write a module implementing GoogleSheets.Callback behaviour for
# converting raw CSV data into useable data structures for your application.
defmodule MyConfigParser do

  @behaviour GoogleSheets.Transform

  def transform(_id, worksheets) do
    # Actual conversion using something like ex_csv library 
    # left as an exercise for the reader.
  end

end

# In your application code
defmodule MyApp do
  def func do
    {:ok, version_key} = GoogleSheets.latest_key :config
    version_key = GoogleSheets.latest_key! :config

    {:ok, version_key, data} = GoogleSheets.fetch :config
    {version_key, data} = GoogleSheets.fetch! :config
  end
end

# The library requires that known good data is present locally
# through filesystem at the application startup phase. 
# The mix task gs.fetch uses the configuration to fetch CSV
# data from spreadsheets and saves them into directories specified
# in the config/config.exs file
mix gs.fetch

```

## How it works

When application starts, the [supervisor](lib/google_sheets/supervisor.ex) creates an `ETS` table named `:google_sheets` and starts an [updater process](lib/google_sheets/updater.ex) for each configured spreadsheet.

During the updater process init phase, initial data is loaded from local filesystem. Before the data is stored into `ETS` table, 



is started for each configured spreadsheet. The updater process is responsible for loading initial data using local files and after that periodically polling the configured google spreadsheet. Whenever the monitored spreadsheet data is changed, a new version of the data is written into `ETS` table.

To allow applications to convert the raw CSV data into more useable format, the updater process will call the configured callback module's on_loaded method before storing data into `ETS` table.

Since the data is initially loaded during the application startup phase, the application code can access.




During the init phase of the updater process, initial data is loaded from configured directory. A `SpreadSheetData` structure is created with multiple worksheets. This data is passed to 



During updater process init phase `CSV` data is loaded from the directory specified in `:dir` configuration option using [GoogleSheets.Loader.FileSystem](lib/google_sheets/loader/file_system.ex) and a [GoogleSheets.SpreadSheetData](lib/google_sheets/loader.ex) structure is constructed.

Before this data is stored into `ETS` table, a call is made to the module 

After the raw CSV data is loaded into a SpreadSheetData structure, that data is passed to 

After data has been loaded one of the one of the `on_loaded` method of the configured `:callback` module implementing [GoogleSheets.Callback](lib/google_sheets/callback.ex) is called. Result of this function is stored in `ETS` table, named by default `:google_sheets` and an unique GUID as key.

After initialization the updater processes sends itself an :update_config message repeatedly. If the spreadsheet data hasn't been changed the `on_unchanged` method of the callback mdoule is called, otherwise the `on_loaded` method is called and a new version of the converted data is stored in ETS table.

To query the latest version of the data, you can use the `GoogleSheets.latest/1` method to get the latest stored version. To keep using the same data without needing to store the whole data in process state, you can request just the key first using `GoogleSheets.latest_key!/1` and then later use `GoogleSheets.get!/2` to get the full data.

## Upgrading from 0.1.x versions

The biggest change is that the during the initial phase data is now loaded always from local directory. This quarantees that there is always a known good state before the application starts and makes using the library easier, since querying the latest data always gives sensible response. The options also have now sane defaults, so you don't need to specify everything explicitly. 

## Publishing Google Spreadsheet

The default way to share a spreadsheet using Google Sheets API is to use `OAuth`, but afaik there is no way to get a permanent `OAuth` token to use with a server. Therefore we must make the spreadsheet public to allow access from a server.

To make things worse, you must both publish the worksheet to web (this allows fetching the worksheet feed and find individual sheet URLs) and share the worksheet (this allows us to fetch the actual CSV content).

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](/docs/share_link.png)

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](/docs/publish_to_web.png)

## Configuration

* __:spreadsheets__ - A list of configurations for each spreadsheet to monitor.

Each __:spreadsheets__ list entry is a keyword list with parameters how to monitor a single spreadsheet:

* __:id__ - Atom used as the name of the updater process and as part of key when saving data into ETS table. The id value is also passed to the `on_loaded` and `on_unchanged` methods.
* __:sheets__ - List of worksheet names to load. If empty, all worksheets in spreadsheet area loaded.
* __:poll_delay_seconds__ - Delay between updates. If 0, only the init phase loading is done. Default is 30.
* __:callback__ - Module implementing GoogleSheets.Callback behaviour. It is required to implement this module in your application code.
* __:loader__ - Module implementing [GoogleSheets.Loader](lib/google_sheets/loader.ex) behaviour. Default is [GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex)

### Mix gs.fetch task

The [gs.fetch](lib/mix/task/gs.fetch.ex) task loads a Google spreadsheet and saves worksheets in specified directory. If no parameters are given, it fetches all spreadsheets specified in the applications :google_sheets configuration and writes data into corresponding directory. You can also provide `-u` and `-d` params to explicitly load a spreadsheet.

```
mix gs.fetch
-u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic 
-d priv/data
```

## More information

* [Google Sheets API documentation](https://developers.google.com/google-apps/spreadsheets/) - More information about the structure of atom feed and about the public vs private visibility.

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.
