# SimpleTicket

A terminal-based PowerShell module for taking, searching through, and managing ticket-based notes.

## Installation

To install, move the folder "SimpleTicket" to your PowerShell modules folder, which can be found by typing this from within PowerShell:

```powershell
$Env:PSMODULEPATH
```

The module should be automatically imported the next time you launch PowerShell.

## Configuration

Configuration is saved in "config.json" in the SimpleTicket directory. If the configuration file does not exist, a default one will be created with the following values:

```json
{
  "editor": {
    "command": "notepad",
    "args": ""
  },
  "directory": {
    "root": "%USERPROFILE%\\Documents\\Notes",
    "daily": "daily",
    "archive": "archive",
    "ticket": "ticket"
  },
  "prefixes": [
    "INC",
    "REQ"
  ],
  "subprefixes": [
    "RITM"
  ]
}
```

`editor.command` is the command or path to your editor of choice. This is used when adding notes with the `-Editor` switch. `editor.args` are any arguments you would like passed to the editor before the filename.

`directory.root` is the directory where you will store your notes. `directory.daily`, `.archive`, and `.ticket` are the subfolder names for daily note files, closed tickets, and open tickets respectively.

`prefixes` are the strings that prefix ticket numbers in your ticketing system.

`subprefixes` are ticket numbers that will require a parent ticket number before they are written.

## Usage

### Add-Note

`Add-Note [[-TicketNumber] <string>] [[-NoteText] <string>]] [-Editor] [<CommonParamters>]`

Adds a note to a ticket or the daily notes file. If the -Editor switch is used, the note is opened in the editor specified in the configuration file. If the note is empty, the user is prompted for input. If the ticket number is not provided, the note is added to the daily notes file. The note is then copied to the clipboard.

Examples:

```powershell
PS> Add-Note INC012345 "Turned it off and on again."
```

If a note is not provided, the function will get input *and will stop once you press enter twice.*

```powershell
PS> Add-Note INC012345
Turned computer off and on again.

PS>
```

You can use the configured editor with the `-Editor` flag:

```powershell
PS> Add-Note INC012345 -Editor
```

If you have provided notes already, they will be in the editor when it opens:

```powershell
PS> Add-Note "Starting my day in paradise" -Editor
```

The function will also take note text from the pipeline:

```powershell
PS> "Turned it off and on again" | Add-Note INC012345 -Editor
```

If the first argument does not match any of the provided ticket prefixes in config.ini, it will be treated like part of the note:

```powershell
PS> Add-Note "Turned computer off." "Then turned it on again."
# Results in "Turned computer off. Then turned it on again." in the daily file.
```

**Notes are expected to be one line per entry.** If multiple lines are given as input, either from the command line or in the editor, they are joined with double slashes, like so:

```powershell
PS> Add-Note INC012345
Turned computer off.
Then turned it on again.
# Results in "Turned computer off. // Then turned it on again."
```

If part of a pipeline, the function returns the ticket number so that you can use it with other SimpleTicket functions.

### Get-Note

`Get-Note [[-TicketNumber] <string>] [<CommonParameters>]`

Displays the notes for a ticket. If the ticket number is not provided, the user is prompted for input. If the ticket number is not found, an error is displayed. Double slashes are used to separate lines in a note, and are displayed as newlines with this function. The note is also copied to the clipboard with some formatting changes.

Examples:

```powershell
PS> Get-Note INC012345
```
```
    INC012345: John Doe @ Office A (555) 555-555 - My computer won't turn on.
    2025-01-18 11:00: Turned it off and on again.
```

```powershell
PS> Add-Note INC012345 "Turned it off and on again." | Get-Note
```
```
Turned it off and on again.

    INC012345: John Doe @ Office A (555) 555-555 - My computer won't turn on.
    2025-01-18 11:00: Turned it off and on again.
```

### Get-LastNote

`Get-LastNote [[-TicketNumber] <string>] [<CommonParameters>]`

Displays the last note for a ticket. If the ticket number is not provided, the user is prompted for input. If the ticket number is not found, an error is displayed. Double slashes are used to separate lines in a note, and are displayed as newlines with this function. The note is also copied to the clipboard with some formatting changes.

Examples:

```powershell
PS> Get-LastNote INC012345
```
```
    2025-01-18 11:00: Turned it off and on again.
```

```powershell
PS> Add-Note INC012345 "Turned it off and on again." | Get-LastNote
```
```
Turned it off and on again.

    2025-01-18 11:00: Turned it off and on again.
```

### Select-Note

`Search-Note [[-Pattern] <string[]>] [<CommonParameters>]`

Searches notes for a term or terms. By default, the search is only performed on tickets only, and excludes any notes in old files merged with Merge-Archive. If the -Daily switch is used, the search is performed on daily notes as well. If the -Old switch is used, the search is performed on merged notes as well.

Examples:

```powershell
PS> Search-Note "off and on"
```
```
    2025-01-18 11:00: Turned it off and on again.
```

### Set-Ticket

`Set-Ticket [[-TicketNumber] <string>] [-Close] [-Open] [<CommonParameters>]`

Moves ticket files between the ticket and archive directories. -Close moves the ticket file from the ticket directory to the archive directory. -Open moves the ticket file from the archive directory to the ticket directory. If a ticket exists in both directories, the ticket files are merged and the merged file is moved to the destination directory.

Examples:

```powershell
PS> Set-Ticket INC012345 -Open
```

```powershell
PS> Add-Note INC012345 "Turned it off and on again." | Set-Ticket -Close
```

### Merge-Archive

`Merge-Archive [-Year] <int> [<CommonParameters>]`

Merges daily and ticket files into yearly archives. Daily files are merged into a single file named YYYY_daily.txt, where YYYY is the year. Ticket files are merged into a single file named YYYY_ticket.txt, where YYYY is the year.

Examples:

```powershell
PS> Merge-Archive 2025
```
