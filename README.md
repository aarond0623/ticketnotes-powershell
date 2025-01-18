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

Adds notes to a daily note file with the current date, and if a ticket number is provided, to the ticket's file as well.

The function is meant to be used without specifying the arguments explicitly. For example:

```powershell
PS> Add-Note INC012345 "Turned computer off and on again."
```

If a note is not provided, the function will get input *and will stop once you press enter twice.*

```powershell
PS> Add-Note INC012345
Turned computer off and on again.

PS>
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

PS>
# Results in "Turned computer off. // Then turned it on again."
```

