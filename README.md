# Google Sheets 

`Google Sheets` is an Elixir library for monitoring changes in a Google spreadsheet and loading data in CSV format. It can also be extended to support other sources, such as local directory with `*.csv` files.

Polling changes in spreadsheet is done by and updater process started for each configured spreadsheet. Whenever the spreadsheet data has changed, a new version is stored into an `ETS table`.

Loading CSV data is done by classes implementing `GoogleSheets.Loader` behaviour. The library has two implementations of the class, one for loading a Google spreadsheet and one for loading `CSV` files from a single directory. The loaders can be used also without the updater processes to manually load CSV data.

## Loading CSV data

### GoogleSheets.Loader behaviour

The basic functionality of the library consists of loading CSV data from a source. This is done by classes implementing [GoogleSheets.Loader](lib/google_sheets/loader.ex) behaviour with a single `load/3` function.

```elixir
defcallback load(sheets :: [binary], previous_version :: binary | nil, 
config :: Keyword.t) :: {version :: binary, GoogleSheets.SpreadSheetData.t} 
| :unchanged | :error
```

__Arguments__

* __sheets__ - List of worksheet names to load. If empty, all available worksheets are loaded.
* __previous_version__ - The version return value of a previous call to the same loader. If nil, the data is always loaded.
* __config__ - Keyword list of loader specific configuration options.

__Return values__

* __{version, spreadsheet}__ - Data has been succesfully loaded. The version return value is loader specific and is used in next call to check if the spreadsheet has changed. The return value spreadsheet is a SpreadSheetData.t structure containing the actual CSV data for all worksheets and some metadata.
* __:unchanged__ - The spreadsheet data hasn't changed since last load call as determined by the previous_version argument.
* __:error__ - If an error was caught while loading data.

__Uncaught errors__

The loaders can easily fail for multitude of reason and not all errors are caught. The updater suprvisor handles this by starting a new process whenever updater crashes. If you call manually the `load/3` function, yous should catch raised exceptions or make sure the application can handle crashes.

### GoogleSheets.Loader.FileSystem

[GoogleSheets.Loader.FileSystem](lib/google_sheets/loader/file_system.ex) implements the loader behaviour by constructing a SpreadSheetData.t structure from all `*.csv` files in a directory. The version parameter is newest modified timestamp of a csv file.

```elixir
{version, spreadsheet} = 
GoogleSheets.Loader.FileSystem.load [], nil, [dir: "priv/data"]
```

See [filesystem_test.exs](test/filesystem_test.exs) for more examples.

### GoogleSheets.Loader.Docs

[GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) loads a Google spreadsheet by first requesting an atom feed describing the spreadsheet and then requesting CSV data for from URLs found in the atom feed.

```elixir

url = "https://spreadsheets.google.com/feeds/worksheets/" <>
"1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"

sheets = ["KeyValue", "KeyTable"]

{version, spreadsheet} = 
GoogleSheets.Loader.Docs.load sheets, nil, [url: url]

```

The `version` return value is equal to `<updated>` element in the atom feed. 

If the `previous_version` parameter is not equal to `<updated>` element value, worksheet CSV data is requested for each worksheet with title matching to one of the passed `sheets` items - or if the sheets list is empty, for all worksheets found in the atom feed.

See [googlesheets_test.exs](test/googlesheets_test.exs) for more examples and [Publishing Google Spreadsheet](#publishing-google-spreadsheet) chapter on how to get an public URL for a spreadsheet.

## Polling spreadsheets

To enable polling, the `:google_sheets` application must be configured with information on how to load a spreadsheet. For each configured spreadsheet, the application starts an [GenServer](lib/google_sheets/updater.ex) process, which periodically uses a loader to check if data has changed and to load actual `CSV` data.

### Configuration

```elixir
config :google_sheets,
  ets_table: :google_sheets,
  supervisor_max_restarts: 3,
  supervisor_max_seconds: 5,
  spreadsheets: [
    [
      id: :spreadsheet_id,
      sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      poll_delay_seconds: 10,
      callback_module: nil,
      loader_init: [
        module: GoogleSheets.Loader.FileSystem, 
        src: "priv/data"
      ],
      loader_poll: [
        module: GoogleSheets.Loader.Docs, 
        src: "https://spreadsheets.google.com/feeds/worksheets/" <>
        "1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
      ]
    ],
    ...
  ]
```

__Configuration options__

* __:ets_table__ - Name of the ETS table where Spreadsheets are stored.
* __:supervisor_max_restarts__ - Supervisor max_restarts parameter.
* __:supervisor_max_seconds__ - Supervisor max_seconds parameter.
* __:spreadsheets__ - A list of configurations for each spreadsheet to monitor.

Each __:spreadsheets__ list entry is a keyword list with parameters how to monitor a single spreadsheet:

* __:id__ - Atom used as the name of the updater process and as part of key when saving spreadsheet data into ETS table.
* __:sheets__ - List of worksheet names to load.
* __:poll_delay_seconds__ - Delay between updates. If 0, only the init phase loading is done.
* __:callback_module__ - Module implementing GoogleSheets.Callback behaviour.
* __:loader_init__ - Loader used during updater init.
* __:loader_poll__ - Loader used during poll updates.

### Data storage

When the application starts a public named ETS table is created. This table holds an entry for the latest version of each spreadsheet and an entry for each version of a loaded spreadsheet.

```elixir
# Querying the key and version of latest load of spreadsheet data,
# when table = :table and spreadsheet id = :spreadsheet
[{lookup_key, version, key}] = 
:ets.lookup :table, {:spreadsheet, :latest}

# Querying the data with a version key returned by previous query
[{lookup_key, data}] = :ets.lookup :table, {:spreadsheet, key}
```

### Updater process

When the application starts, the supervisor starts an [updater](lib/google_sheets/updater.ex) process for each configured spreadsheet. The registered name of the process is equal to the `:id` configuration value. This allows sending an `:update` message to process to trigger checking of updated data manually.

During the GenServer `init/1` callback, the updater process checks if there is already an entry stored in the `ETS` table for the spreadsheet. If not, it loads initial data using the module set in `:loader_init` configuration option and saves an entry in `ETS` table.

To trigger updates the process sends an `:update` message to itself with a delay configured in `:poll_delay_seconds`. When this message is received, the process uses loader configured in `:loader_poll` to load CSV data. If new data is available, it's stored in `ETS` table and a new update is scheduled.

### Callbacks

Storing raw `CSV` data into an `ETS` table is not going to be very useful for most applications. To transform loaded data before saving it, the `:calback_module` configuration option can be set to a module implementing [GoogleSheets.Callback](lib/google_sheets/callback.ex) behaviour.

The behaviour defines three functions, `on_loaded/2`, `on_saved/2` and `on_unchanged/1`. The `on_unchanged/1` function is called whenever a loader returns `:unchanged` as result. The `on_saved/2` and `on_loaded/2` functions are called before and after saving data into `ETS` table by the `update_ets_entry/2` function of [udpater.ex](lib/google_sheets/updater.ex) module.

```elixir
# Snippet from the update_ets_entry/2 function of updater.ex
data = on_loaded callback_module, id, spreadsheet
:ets.insert Utils.ets_table, {{id, key}, data}
:ets.insert Utils.ets_table, {{id, :latest}, version, key}
on_saved callback_module, id, data
```

Normal use case would be to use something like [ex_csv](https://hex.pm/packages/ex_csv) to parse the CSV data and return a map to be saved into ETS table. The only limitation about the data is that it can be saved `ETS` table in one entry.

The `on_saved` and `on_uchanged` callbacks can be used to trigger some other actions.

## Helpers

### GoogleSheets.Utils

The GoogleSheets utils exposes a few methods to query the latest version of a spreadsheet.

```elixir
```


### Mix gs.fetch task

The [gs.fetch](lib/mix/task/gs.fetch.ex) task loads a Google spreadsheet and saves worksheets in specified directory. An example on how to use the task is shown below.

```
mix gs.fetch
-u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic 
-d priv/data
```

Purpose of this task is to help having a preloaded configuration available at deployment time. By configuring the `:loader_init` with `GoogleSheets.Loader.FileSystem` and loading data from disc makes sure that we have some configuration available, even if Google wouldn't be responding.

## Publishing Google Spreadsheet

The default way to share a spreadsheet using Google Sheets API is to use `OAuth`, but afaik there is no way to get a permanent `OAuth` token to use with a server. Therefore we must make the spreadsheet public to allow access from a server.

To make things worse, you must both publish the worksheet to web (this allows fetching the worksheet feed and find individual sheet URLs) and share the worksheet (this allows us to fetch the actual CSV content).

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](/docs/share_link.png)

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](/docs/publish_to_web.png)

## More information

* [Google Sheets API documentation](https://developers.google.com/google-apps/spreadsheets/) - More information about the structure of atom feed and about the public vs private visibility.

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.
