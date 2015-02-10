# Google Sheets

## What is this all about?

This is a simple Elixir library for fetching sheets in CSV format from a single Google Spreadsheet. Main purpose is to make constant updating of game configuration easy in a client - server architecture.

## Usage

There are two main use cases for this library: either use it as a library and call the GoogleSheets.Loader.load method manually, or confgure and use the :google_sheets application to periodically update CSV data in a ETS table.

### Using the GoogleSheets.Loader manually

The easiest way to use the library is to simply call GoogleSheets.Loader.Load(key, sheets \\ []) method. The key parameter is the published 


There are two use cases for this: one to use the GoogleSheet.Loader.load function to manually fetch spreadsheet data and process it further. The 


Another use case is to start the application, which will periodically poll the latest CSV data and write it to ETS table. This data can then be used to dynamically configure the host application.

## Making worksheet public.

The default way to share links in Google Sheets API is to use oauth (see the more information chapter for more information), but this is not feasible, since afaik there is no way to get permanent oauth token. Therefore we must make the Worksheet public to be able to fetch document.

To make things worse, you must both publish the worksheet to web (this allows fetching the worksheet feed and find individual sheet URLs) and share the worksheet (this allows us to fetch the actual CSV content).

Sharing link is on the top right corner of the worksheet document and it opens following dialog:

![Sharing dialog](/docs/share_link.png)

Publish to web is found in the File menu and it opens a dialog shown below:

![Publish to Web](/docs/publish_to_web.png)

## More information

See the Google Sheets API documentation at https://developers.google.com/google-apps/spreadsheets/ see especially the documentation about public vs private visibilty at https://developers.google.com/google-apps/spreadsheets/#sheets_api_urls_visibilities_and_projections

## Credits

Credits for the original C# implementation goes to Harri Hätinen https://github.com/hhatinen and to Teemu Harju https://github.com/tsharju for the original Elixir implementation.

