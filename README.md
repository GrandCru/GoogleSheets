# Google Sheets 

An Elixir library and application for fetching and polling Google spreadsheet data in CSV format. 

Main purpose of this application is to allow runtime configuration of an application. This is achieved by configuring one or more spreadsheets for monitoring and storing a new version of the spreadsheet in ETS table whenever it has been changed. To use the data the host application can query the latest version and load the spreadsheet data from ETS table.

It is also possible to use the CSV data loading modules without launching any updater processes.

## Loading CSV data

### GoogleSheets.Loader behaviour

The basic functionality of the library consists of loading CSV data from a source. This is done by classes implementing [GoogleSheets.Loader](lib/google_sheets/loader.ex) behaviour.

The behaviour itself defines just a single load/3 function, as shown below:

```elixir
defcallback load(sheets :: [binary], previous_version :: binary | nil, 
config :: Keyword.t) :: {version :: binary, GoogleSheets.SpreadSheetData.t} 
| :unchanged | :error
```

__Arguments__

* __sheets__ - List of worksheet names to load. If empty all available worksheets are loaded.
* __previous_version__ - Data which can be used to check if the spreadsheet has been updated since last load time. Usually value returned by a previous call to same loader implementation.
* __config__ - Keyword list of loader specific configuration options.

__Return values__

* __{version, spreadsheet}__ - Data has been succesfully loaded. The version return value is loader specific and can be used in next call to short circuit loading if data hasn't been changed. The spreadsheet is a SpreadSheetData.t structure containing the actual CSV data for all worksheets.
* __:unchanged__ - The spreadsheet data hasn't changed since last load call as determined by the previous_version argument.
* __:error__ - If an error was caught while loading data.

__Errors__

It is important to understand that especially the [GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) can easily fail and raise exception. It's not uncommon for the retuned CSV data contain #Error values in cells or the requests to timeout. To safely try loading, the load call should catch raised exceptions or be called from a supervised process.

### GoogleSheets.Loader.FileSystem

[GoogleSheets.Loader.FileSystem](lib/google_sheets/loader/file_system.ex) implements the loader behaviour by loading CSV files in a specified directory. The config parameter is a keyword list with :dir key containing directory where to load data. 

See [filesystem_test.exs](test/filesystem_test.exs) for examples how to use it.

### GoogleSheets.Loader.docs
[GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) loads a Google spreadsheet in CSV format.

First step is requesting an atom feed describing the spreadsheet. The atom feed has entries with URLs to worksheet data in CSV format and an entry for the the last updated timestamp. If the passed previous_version variable is equal to the atom feed last_updated entry, the loader returns :unchanged atom. Otherwise it request the CSV data URL for each worksheet to be loaded.

The config parameter is a keyword lis with :url key value equal to the atom feed URL. See [googlesheets_test.exs](test/googlesheets_test.exs) for and examples how to use the module manually and [Publishing Google Spreadsheet](#publishing-google-spreadsheet) chapter on how to publish and get an URL for a spreadsheet.

## Polling spreadsheets and storing to ETS

The polling functionality is implemented by a simple [GenServer](lib/google_sheets/updater.ex), which uses configured loaders to load CSV data and then schedules next udpate after delay by sending a delayed :update message to itself.

### Configuration

To use the polling functionality, the :google_sheets application must be configured with data how to load each monitored spreadsheet and some generic data, like ETS table where to save loaded results.

Below is an example configuration polling two spreadsheets:

```elixir
config :google_sheets,
  ets_table: :google_sheets,
  supervisor_max_restarts: 3,
  supervisor_max_seconds: 5,
  spreadsheets: [
    [
      id: :multiple_worksheets,
      sheets: ["KeyValue", "KeyTable", "KeyIndexTable"],
      poll_delay_seconds: 10,
      callback_module: nil,
      loader_init: [
        module: GoogleSheets.Loader.FileSystem, 
        src: "priv/data"
      ],
      loader_poll: [
        module: GoogleSheets.Loader.Docs, 
        src: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
      ]
    ],
    [
      id: :single_worksheet,
      sheets: ["KeyValue"],
      poll_delay_seconds: 10,
      callback_module: nil,
      loader_init: [
        module: GoogleSheets.Loader.FileSystem, 
        src: "priv/data"
      ],
      loader_poll: [
        module: GoogleSheets.Loader.Docs, 
        src: "https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic"
      ]
    ]
  ]
```

__Configuration options__

* :ets_table - Atom identifying the ETS table where Spreadsheets are stored.
* :supervisor_max_restarts - Supervisor max_restarts parameter.
* :supervisor_max_seconds - Supervisor max_seconds parameter.
* :spreadsheets - A list of configuration options with an entry for each monitored spreadsheet.

Each monitored __:spreadsheets__ list entry is a keyword list, with the following parameters:

* :id - Atom used as key in ETS table and as the updater process name.
* :sheets - List of worksheet names to load.
* :poll_delay_seconds - Delay between updates, if configured as 0, only the init phase update is done.
* :callback_module - Module implementing GoogleSheets.Callback behaviour.
* :loader_init - Loader used during updater init.
* :loader_poll - Loader used during poll updates.

#### Callbacks

The [GoogleSheets.Callback](lib/callback.ex) module defines behaviour describing callbacks the udpater makes after a spreadsheet is first loaded.

The on_loaded callback can be used to parse and convert the raw CSV data into a format that the application requires. For example converting into a Map etc.

The on_saved and on_unchanged callbacks are meant for notifications. on_saved is called whenever the ETS entry is updated and on_unchanged when the document was polled, but the contents didn't change.

## Helpers

### Mix gs.fetch task

The [gs.fetch](lib/mix/task/gs.fetch.ex) task loads a Spreadsheet and saves the worksheets in specified directory. An example on how to use the task is shown below.

```
mix gs.fetch
-u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic 
-d priv/data
```

## Publishing Google Spreadsheet

The default way to share links in Google Sheets API is to use oauth (see the more information chapter for API documentation), but for a server service this is not possible since you can't get a permanent oauth token afaik. Therefore we must make the spreadsheet public to be able to fetch document and all worksheets.

To make things worse, you must both publish the worksheet to web (this allows fetching the worksheet feed and find individual sheet URLs) and share the worksheet (this allows us to fetch the actual CSV content).

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](/docs/share_link.png)

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](/docs/publish_to_web.png)

## More information

See the [Google Sheets API documentation](https://developers.google.com/google-apps/spreadsheets/) for more information about the structure of atom feed and about the public vs private visibility.

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.
