function Add-Note() {
	<#
	.SYNOPSIS
	Adds a note to a ticket or the daily notes file.

	.DESCRIPTION
	Adds a note to a ticket or the daily notes file. If the -Editor switch is
	used, the note is opened in the editor specified in the configuration file.
	If the note is empty, the user is prompted for input. If the ticket number is
	not provided, the note is added to the daily notes file. The note is then
	copied to the clipboard.

	.PARAMETER TicketNumber
	The ticket number to add the note to. If the ticket number is not provided,
	the note is only added to the daily notes file. For ease of use, if this
	parameter does not match the ticket number format, it is considered part of
	the note text.

	.PARAMETER NoteText
	The text of the note to add. If this parameter is not provided, the user is
	prompted for input.

	.INPUTS
	System.String. Takes NoteText as input.

	.OUTPUTS
	System.String. Returns TicketNumber as output if not the last part of a
	pipeline.

	.EXAMPLE
	PS> Add-Note INC012345 "Turned it off and on again."

	.EXAMPLE
	PS> Add-Note INC012345

	.EXAMPLE
	PS> Add-Note INC012345 -Editor

	.EXAMPLE
	PS> Add-Note "Starting my day in paradise" -Editor

	.EXAMPLE
	PS> "Turned it off and on again" | Add-Note INC012345 -Editor
	#>
	param(
		[Parameter(Position=0, Mandatory=$false)][String] $TicketNumber,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)][String] $NoteText,
		[Switch] $Editor
	)

	Begin{
		$notesdir = $TNConfig.directory.root
		$ticketdir = "$notesdir\$($TNConfig.directory.ticket)"
		$archivedir = "$notesdir\$($TNConfig.directory.archive)"
		$dailydir = "$notesdir\$($TNConfig.directory.daily)"
		$TicketNumber = $TicketNumber.ToUpper()
		# Test if the ticket number is valid. If not, consider it part of the note.
		$AllPrefixes = $TNConfig.prefixes + $TNConfig.subprefixes
		if ($TicketNumber -notmatch "^($($AllPrefixes -join '|'))(\d+)$") {
			$NoteText = @($TicketNumber, $NoteText) -join ' '
			$TicketNumber = $null
		}

		# If there's absolutely no note text, prompt the user for input.
		if (!($NoteText) -and !($MyInvocation.ExpectingInput) -and !($Editor)) {
			$NoteText = while($true) {
				Read-Host | Set-Variable r; if (!$r) { break }; "$r`n"
			}
			$NoteText = $NoteText.Trim()
			$NoteText = ($NoteText -Split "`n") -join " //"
		}
	}

	Process {
		# Open the editor if the -Editor switch is used.
		if ($Editor) {
			Push-Location $notesdir
			Add-Content -Path "temp_note.txt" $NoteText -Encoding UTF8
			$EditorArgs = $TNConfig.editor.args, '"temp_note.txt"' -join ' '
			if ($TicketNumber) {
				if (issubticket $TicketNumber) {
					# This is a subticket number. Find the parent ticket.
					$SubTicket = $TicketNumber
					$TicketNumber = findparent $SubTicket $ticketdir

					if (!($TicketNumber)) {
						# Couldn't find the parent ticket. Create a new one.
						$TicketNumber = (Read-Host "Parent Ticket #").ToUpper()
					}
				}
				$TicketFile = "$($TNConfig.directory.ticket)\$TicketNumber.txt"
				if (Test-Path $TicketFile) {
					# Special case for notepad because it does not support multiple files from the command line.
					if ($TNConfig.editor.command -eq "notepad" -or $TNConfig.editor.command -eq "notepad.exe") {
						Start-Process $TNConfig.editor.command -Wait -ArgumentList $EditorArgs
					} else {
						# Open the temp_note file and the ticket file in the editor.
						$EditorArgs, "`"$TicketFile`"" -join ' '
						Start-Process $TNConfig.editor.command -Wait -ArgumentList $EditorArgs
					}
				} else {
					# Open only the temp_note file.
					Start-Process $TNConfig.editor.command -Wait -ArgumentList $EditorArgs
				}
			} else {
				Start-Process $TNConfig.editor.command -Wait -ArgumentList $EditorArgs
			}
			Pop-Location
			$NoteText = Get-Content -Path $notesdir\temp_note.txt -Encoding UTF8
			$NoteText = $NoteText -Join ' //' # Replace newlines with double slashes.
			$NoteText = $NoteText -Replace (' //([^ ])', ' // $1') # Add a space after each double slash.
			$NoteText = $NoteText -Replace ('/s+///s+', ' // ') # Remove extra spaces around double slashes.
			Remove-Item -Path $notesdir\temp_note.txt
		}

		if (($NoteText.Length -eq 0) -or (($NoteText.Length -eq 1) -and ($NoteText[0] -match "^\s+$|^\0$"))) {
			if (!($TicketNumber)) {
				return
			}
			# For initializing tickets without a note.
			if (issubticket $TicketNumber) {
				$TicketNumber = findparent $SubTicket $ticketdir
				if ($TicketNumber) {
					Write-Error "Ticket exists. Please provide a note."
					return
				} else {
					$TicketNumber = (Read-Host "Parent Ticket #").ToUpper()
				}
			}
			$TicketFile = "$ticketdir\$TicketNumber.txt"
			if ((Test-Path $TicketFile) -or (Test-Path "$archivedir\$TicketNumber.txt")) {
				Write-Error "Ticket exists. Please provide a note."
				return
			} else {
				$header = createheader $TicketNumber
				Add-Content -Path $TicketFile $header -Encoding UTF8
			}
		} else {
			$CopyNote = ""
			$NoteText = $NoteText | Foreach-Object { $_.Trim() }
			$NoteText = @($NoteText) -join " // "
			$time = Get-Date -Format "HH:mm"
			$today = Get-Date -Format "yyyy-MM-dd"
			$DailyFile = "$dailydir\$today.txt"
			if ($TicketNumber) {
				if (issubticket $TicketNumber) {
					$SubTicket = $TicketNumber
					$TicketNumber = findparent $SubTicket $ticketdir
					if (!($TicketNumber)) {
						$TicketNumber = (Read-Host "Parent Ticket #").ToUpper()
					}
				}
				if ($SubTicket) {
					$NoteText = "[$SubTicket] $NoteText"
				}
				$TicketFile = "$ticketdir\$TicketNumber.txt"
				if (!(Test-Path $TicketFile)) {
					if (Test-Path "$archivedir\$TicketNumber.txt") {
						Move-Ticket $TicketNumber -Open
					} else {
						$header = createheader $TicketNumber
						Add-Content -Path $TicketFile $header -Encoding UTF8
					}
				}
				if ($CopyNote -ne "") {
					$CopyNote = "$CopyNote`n"
				}
				$CopyNote = "$CopyNote$($NoteText -Replace ("^\[($($TNConfig.subprefixes -join '|'))(\d+)\] ", '') -Replace ('(?<= )// ', "`n"))"
				Set-Clipboard -Value $CopyNote
				$DailyNote = "$($time): [$TicketNumber] $NoteText"
				Add-Content -Path $DailyFile $DailyNote -Encoding UTF8
				$TicketNote = "$today $($time): $NoteText"
				Add-Content -Path $TicketFile $TicketNote -Encoding UTF8
			} else {
				$DailyNote = "$($time): $NoteText"
				Add-Content -Path $DailyFile $DailyNote -Encoding UTF8
			}
		}
		if ($TicketNumber) {
			if ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength) {
				$TicketNumber
			}
		}
	}

	End {}
}
