# Google Sheets 

`Google Sheets` is an Elixir library for fetching Google spreadsheet data in CSV format. It supports both saving `*.csv` files into local directory as well as monitoring changes in a spreadsheet during application runtime. The loaded `CSV` data is stored in an `ETS table`, where application can access it.

[![Hex.pm Version](http://img.shields.io/hexpm/v/google_sheets.svg?style=flat)](https://hex.pm/packages/google_sheets)

## Quick start

```elixir
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
      callback: ConfigParser,
      dir: "priv/data",
      url: "https://spreadsheets.google.com/feeds/worksheets/" <>
           "19HcQV5Z-uTXaVxjm2jVJNGNFv0pzA_cgdBTWMe4a77Y/public/basic",
    ]
  ]

# Write a module implementing GoogleSheets.Callback behaviour for
# converting raw CSV data into useable data structures for your
# application.
defmodule ConfigParser do

  @behaviour GoogleSheets.Callback

  def on_loaded(_id, %GoogleSheets.SpreadSheetData{} = spreadsheet) do
    Enum.map spreadsheet.sheets fn sheet -> parse_config sheet end)
  end

  def on_saved(_id, _data) do
  end

  def on_unchanged(_id) do
  end

  # Internal implementation
  defp parse_locale(%GoogleSheets.WorkSheetData{} = ws) do
    # Actual conversion using something like ex_csv library 
    # left as an exercise for the reader.
  end
end

# In your application code
defmodule MyApp do
  def func do
    {:ok, version_key, data} = GoogleSheets.latest :config
    {version, data} = GoogleSheets.latest! :config

    {:ok, version_key} = GoogleSheets.latest_version_key :config
    version_key = GoogleSheets.latest_version_key! :config

    {:ok, data} = GoogleSheets.latest_data :config
    data = GoogleSheets.latest_data! :config

    {:ok, data} = GoogleSheets.get :config, version_key
    data = GoogleSheets.get! :config, version_key
  end
end

# Fetch initial CSV data form all configured spreadsheets with:
mix gs.fetch

# And make sure you're spreadsheet is published, see the 
# Publishing Google spreadsheet how to do it.

```

## How it works

When the application starts, an [updater process](lib/google_sheets/updater.ex) is started for each configured spreadsheet. During updater process init phase `CSV` data is loaded from the directory specified in `:dir` configuration option using [GoogleSheets.Loader.FileSystem](lib/google_sheets/loader/file_system.ex).

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

* __:ets_table__ - Name of the ETS table where Spreadsheets are stored, default is `:google_sheets`
* __:supervisor_max_restarts__ - Supervisor max_restarts parameter.
* __:supervisor_max_seconds__ - Supervisor max_seconds parameter.
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
