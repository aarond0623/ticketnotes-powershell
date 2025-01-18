function Add-Note() {
	param(
		[Parameter(Position=0, Mandatory=$false)][String] $TicketNumber,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)][String] $NoteText,
		[Switch] $Editor
	)

	Begin{
		$notesdir = $STConfig.directory.root
		$ticketdir = "$notesdir\$($STConfig.directory.ticket)"
		$archivedir = "$notesdir\$($STConfig.directory.archive)"
		$dailydir = "$notesdir\$($STConfig.directory.daily)"
		$TicketNumber = $TicketNumber.ToUpper()
		# Test if the ticket number is valid. If not, consider it part of the note.
		$AllPrefixes = $STConfig.prefixes + $STConfig.subprefixes
		if ($TicketNumber -notmatch "^($($AllPrefixes -join '|'))(\d+)$") {
			$NoteText = $TicketNumber + " " + $NoteText
			$TicketNumber = $null
		}

		# If there's absolutely no note text, prompt the user for input.
		if (!($NoteText) -and !($MyInvocation.ExpectingInput) -and !($Editor)) {
			$NoteText = while($true) {
				Read-Host | Set-Variable r; if (!$r) { break }; $r
			}
		}
		# Open the editor if the -Editor switch is used.
		if ($Editor) {
			Push-Location $notesdir
			Add-Content -Path "temp_note.txt" $NoteText -Encoding UTF8
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
				$TicketFile = "$($STConfig.directory.ticket)\$TicketNumber.txt"
				if (Test-Path $TicketFile) {
					# Special case for notepad because it does not support multiple files from the command line.
					if ($STConfig.editor.command -eq "notepad" -or $STConfig.editor.command -eq "notepad.exe") {
						Start-Process $STConfig.editor.command -Wait -ArgumentList ($STConfig.editor.args + @("temp_note.txt"))
					} else {
						# Open the temp_note file and the ticket file in the editor.
						Start-Process $STConfig.editor.command -Wait -ArgumentList ($STConfig.editor.args + @("temp_note.txt", $TicketFile))
					}
				} else {
					# Open only the temp_note file.
					Start-Process $STConfig.editor.command -Wait -ArgumentList ($STConfig.editor.args + @("temp_note.txt"))
				}
			} else {
				Start-Process $STConfig.editor.command -Wait -ArgumentList ($STConfig.editor.args + @("temp_note.txt"))
			}
			Pop-Location
			$NoteText = Get-Content -Path $notesdir\temp_note.txt -Encoding UTF8
			$NoteText = $NoteText -Join ' //' # Replace newlines with double slashes.
			$NoteText = $NoteText -Replace (' //([^ ])', ' // $1') # Add a space after each double slash.
			Remove-Item -Path $notesdir\temp_note.txt
		}
	}

	Process {
		if (($NoteText.Length -eq 0) -or (($NoteText.Length -eq 1) -and ($NoteText[0] -eq "`0"))) {
			if (!($TicketNumber)) {
				return
			}
			# For initializing tickets without a note.
			if (issubticket $TicketNumber) {
				$TicketNumber = findparent $SubTicket $ticketdir
				if (TicketNumber) {
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
					if (!(TicketNumber)) {
						$TicketNumber = (Read-Host "Parent Ticket #").ToUpper()
					}
				}
				if ($SubTicket) {
					$NoteText = "[$SubTicket] $NoteText"
				}
				$TicketFile = "$ticketdir\$TicketNumber.txt"
				if (!(Test-Path $TicketFile)) {
					if (Test-Path "$archivedir\$TicketNumber.txt") {
						Write-Error "Ticket is archived."
						return
					} else {
						$header = createheader $TicketNumber
						Add-Content -Path $TicketFile $header -Encoding UTF8
					}
				}
				if ($CopyNote -ne "") {
					$CopyNote = "$CopyNote`n"
				}
				$CopyNote = "$CopyNote$($NoteText -Replace ("^\[($($STConfig.subprefixes -join '|'))(\d+)\] ", '') -Replace ('(?<= )// ', "`n"))"
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
