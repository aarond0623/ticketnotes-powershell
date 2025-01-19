function Set-Ticket {
	[CmdletBinding()]
	param(
		[Alias("Closed", "C")][Switch] $Close,
		[Alias("Opened", "O")][Switch] $Open,
		[Parameter(Position=0, ValueFromPipeline=$true)][String] $TicketNumber
	)

	Begin {
		if (!($PSBoundParameters.ContainsKey("TicketNumber"))) {
			try {
				$TicketNumber = @(Get-LastArgs)
			} catch {
				$TicketNumber = Read-Host "Ticket"
			}
		}

		if (!$TicketNumber) {
			Write-Error "No ticket number provided"
			return
		}

		$notesdir = $STConfig.directory.root
		$ticketdir = "$notesdir\$($STConfig.directory.ticket)"
		$archivedir = "$notesdir\$($STConfig.directory.archive)"
		$TicketNumber = $TicketNumber.ToUpper()

		if ($Close -and $Open) {
			throw "Cannot close and open a ticket at the same time"
		}
		if (!($Close -or $Open)) {
			throw "Must specify either -Close or -Open"
		}
		if ($Close) {
			$fromdir = $ticketdir
			$todir = $archivedir
			$success = "Ticket closed."
		}
		if ($Open) {
			$fromdir = $archivedir
			$todir = $ticketdir
			$success = "Ticket opened."
		}
	}

	Process {
		if (issubticket $TicketNumber) {
			$SubTicket = $TicketNumber
			$TicketNumber = findparent $TicketNumber @($ticketdir, $archivedir)
			if (!$TicketNumber) {
				$TicketNumber = (Read-Host "Parent Ticket #").ToUpper()
			}
		}
		$TicketFile = $TicketNumber
		if (!(Test-Path "$fromdir\$TicketFile")) {
			$TicketFile = "$TicketFile.txt"
		}
		if (!(Test-Path "$fromdir\$TicketFile")) {
			$msg = "Ticket $TicketNumber not found in $fromdir."
			if (Test-Path "$todir\$TicketFile") {
				$msg += "`nThis ticket does exist in $todir, though."
			}
			Write-Error $msg
			return
		}
		try {
			Move-Item -Path "$fromdir\$TicketFile" -Destination "$todir\$TicketFile" -ErrorAction Stop
			Write-Host $success
		} catch {
			# We have duplicate tickets and have to merge them
			Get-Content "$ticketdir\$TicketFile" -Encoding UTF8 `
			| Add -Content -Path "$archivedir\$TicketFile" -Encoding UTF8
			Remove-Item "$ticketdir\$TicketFile"
			Move-Item -Path "$archivedir\$TicketFile" -Destination "$todir\$TicketFile"
			Write-Host $success
		}
		if ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength) {
			$TicketNumber
		}
	}

	End {}
}
