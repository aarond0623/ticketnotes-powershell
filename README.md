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
