# Google Sheets 

Elixir library for fetching and polling Google Spreadsheet data in CSV format. 

Main purpose of the library is to enable constant updates of configuration data stored in a Google Spreadsheet, without the need for deploying a new server with new configuration. 

## Usage

The library can be used to simply fetch Spreadsheet data manually using the provided GoogleSheets.Loader.Docs module. The module first loads an atom feed describing the spreadsheet, when it was last updated and the URLs for requesting CSV data for an individual worksheet. After that it requests the data for all worksheets and returns an GoogleSheets.SpreadSheetData.t structure with loaded data.

The main use case leverages the loader functionality by launching configurable updater processes, which peridodically checks if the configured Spreadsheet(s) has been modified and stores the loaded data into ETS table. The updater process can also be configured to preprocess the loaded CSV data, so that parsing CSV data is done only once.

### GoogleSheets.Loader behaviour

The [GoogleSheets.Loader](lib/google_sheets/loader.ex) module defines a behaviour which all modules loading CSV data implement. The library has two concrete implementations of this class, [GoogleSheets.Loader.Docs](lib/google_sheets/loader/docs.ex) which loads data from a Google Spreadsheet and [GoogleSheets.Loader.FileSystem](lib/google_sheets/loader/file_system.ex) which loads spreadsheet data from a directory.

All of the Loader modules behaviours implement the load callback function as specified below.

```elixir
defcallback load(sheets :: [binary], last_updated :: binary | nil, config :: Keyword.t) :: GoogleSheets.SpreadSheetData.t | :unchanged | :error
```

The sheets parameter is a list of Worksheet names that should be loaded, if empty or nil all worksheets in the Spreadsheet are loaded.

The last_updated parameter is a string, which allows a poller to short circuit loading.

The config parameter is loader specific list of options, but both the Docs and Filesystem loader assume that there is as src parameter given. For actual implementation see the example [config.exs](config/config.exs) or tests how it is used.

### GoogleSheets.Updater

Depending on the configuration, you can have multiple updater processes (GenServers) running, each of them polling updates to a Spreadsheet.

Below is an example configuration, which is the configuration used, when running "make run" command on project directory. It launches two [GoogleSheets.Updater](lib/updater.ex) processes (both of them polling the same Spreadsheet).

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

#### Configuration options

* :ets_table - Atom id of the ETS table created and where the loaded Spreadsheest are stored.
* :supervisor_max_restarts - See Elixir supervisor documentation for max_restarts parameter.
* :supervisor_max_seconds - See Elixir supervisor documentation for max_seconds parameter.

The :spreadsheets option is a list with each Spreadsheet to poll having it's own entry:

* :id - Atom used as the key for storing loaded Spreadsheet in ETS table
* :sheets - List with names of sheets to poll, if empty, all worksheets are loaded.
* :poll_delay_seconds - How many seconds to wait before next update.
* :callback_module - Module implementing GoogleSheets.Callback behaviour, see next chapter how they can be used to convert raw CSV data before it's stored into ETS table and get notifications.
* :loader_init - Configuration for GoogleSheets.Loader implementation used during the first initial loading.
* :loader_poll - Configuration for GoogleSheets.Loader implementation used after the first load has been completed.

#### Callbacks

The [GoogleSheets.Callback](lib/callback.ex) module defines behaviour describing callbacks the udpater makes after a spreadsheet is first loaded.

The on_loaded callback can be used to parse and convert the raw CSV data into a format that the application requires. For example converting into a Map etc.

the on_saved and on_unchanged callbacks are meant for notification. on_saved is called whenever the ETS entry is updated and on_unchanged when the document was polled, but the contents didn't change.

### Mix gs.fetch task

The loader functionality is used by the [gs.fetch](lib/mix/task/gs.fetch.ex) task for saving a Spreadsheet worksheets in CSV format to a directory. The project [Makefile](Makefile) has an example task, which loads a Spreadsheet and saves all worksheets in it to priv/data folder.

```
mix gs.fetch -src https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic -dir priv/data
```

Purpose of this is to have a known good configuration deployed with the server and if the updater module is configured to load data first from filesystem and then start polling, we don't end up in a situation where the whole updater process ends, because it crashed more often than what the supervisor max_restarts and max_seconds parameter allows. This naturally requires that the poll period is long enough.

## Publishing Google Spreadsheet

The default way to share links in Google Sheets API is to use oauth (see the more information chapter for API documentation), but for a server service this is not feasible. Reasong being that afaik there is no way to get permanent oauth token. Therefore we must make the Worksheet public to be able to fetch document and all worksheets.

To make things worse, you must both publish the worksheet to web (this allows fetching the worksheet feed and find individual sheet URLs) and share the worksheet (this allows us to fetch the actual CSV content).

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](/docs/share_link.png)

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](/docs/publish_to_web.png)

## More information

See the Google Sheets API documentation at https://developers.google.com/google-apps/spreadsheets/ see especially the documentation about public vs private visibilty at https://developers.google.com/google-apps/spreadsheets/#sheets_api_urls_visibilities_and_projections

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.

