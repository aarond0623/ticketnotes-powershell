function helper() {
	[CmdletBinding()]
	param([Parameter(Position=0, ValueFromPipeline=$true)][String] $TicketNumber)

	Begin {
		$notesdir = $TNConfig.directory.root
		$ticketdir = "$notesdir\$($TNConfig.directory.ticket)"
		$archivedir = "$notesdir\$($TNConfig.directory.archive)"
		$TicketNumber = $TicketNumber.ToUpper()

		if (!($PSBoundParameters.ContainsKey('TicketNumber'))) {
			try {
				$TicketNumber = @(Get-LastArgs)
			} catch {
				$TicketNumber = Read-Host "Ticket"
			}
		}
	}

	Process {
		if (issubticket $TicketNumber) {
			$SubTicket = $TicketNumber
			$TicketNumber = findparent $SubTicket @($ticketdir, $archivedir)
			if (!($TicketNumber)) {
				$TicketNumber = (Read-Host "Parent Ticket #").ToUpper()
			}
		}
		if (!(Test-Path $TicketNumber)) {
			# Check ticket directory
			$TicketFile = "$ticketdir\$TicketNumber.txt"
		}
		if (!(Test-Path $TicketFile)) {
			# Check archive directory
			$TicketFile = "$archivedir\$TicketNumber.txt"
		}
		if (!(Test-Path $TicketFile)) {
			# Check any archived grouped ticked files
			$TicketText = Get-ChildItem $archivedir -Filter "*_ticket.txt" `
			| Select-String -Pattern "$($TicketNumber):|\[$TicketNumber\]" `
			| Foreach-Object { $_.Line }
			if (!($TicketText)) {
				# Couldn't find the ticket anywhere
				return
			}
		}
		if (!($TicketText)) {
			$TicketText = Get-Content $TicketFile -Encoding UTF8 `
			| Where-Object { $_.trim() -ne "" }
		}
		if ($SubTicket) {
			$TicketText = $(($TicketText | Where-Object { $_ -NotMatch "^\d{4}-\d{2}-\d{2}"}); `
			($TicketText | Where-Object { $_ -Match "\[$SubTicket\]" }))
		}
		$TicketText
	}

	End {}
}

function Get-Note() {
	<#
	.SYNOPSIS
	Displays the notes for a ticket.

	.DESCRIPTION
	Displays the notes for a ticket. If the ticket number is not provided, the
	user is prompted for input. If the ticket number is not found, an error is
	displayed. Double slashes are used to separate lines in a note, and are
	displayed as newlines with this function. The note is also copied to the
	clipboard with some formatting changes.

	.PARAMETER TicketNumber
	The ticket number to display notes for. If this parameter is not provided,
	the user is prompted for input.

	.INPUTS
	System.String. Takes TicketNumber as input.

	.OUTPUTS
	System.String. Returns TicketNumber as output if not the last part of a
	pipeline.

	.EXAMPLE
	PS> Get-Note INC012345

	.EXAMPLE
	PS> Add-Note INC012345 "Turned it off and on again." | Get-Note
	#>
	[CmdletBinding()]
	param(
		[Parameter(Position=0, ValueFromPipeline=$true)][String] $TicketNumber
	)

	Begin {
		if (!($PSBoundParameters.ContainsKey('TicketNumber'))) {
			try {
				$TicketNumber = @(Get-LastArgs)
			} catch {
				$TicketNumber = Read-Host "Ticket"
			}
		}
	}

	Process {
		$TicketText = helper $TicketNumber
		if (!($TicketText)) {
			Write-Error "Ticket $TicketNumber not found."
			return
		}
		if ($TicketText.Length -eq 0) {
			return
		}

		$DisplayText = $TicketText -Split '(?<= )// '
		$DisplayText = Format-Wordwrap $DisplayText
		Write-Host
		foreach ($line in $DisplayText) {
			Write-Host "    $line"
		}
		Write-Host
		$TicketText = $TicketText -Join "`n`n"
		$TicketText = $TicketText -Replace ('(?<= )// ', "`n")
		try {
			Set-Clipboard $TicketText
		} catch { }
		if ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength) {
			$TicketNumber
		}
	}

	End {}
}

function Get-LastNote() {
	<#
	.SYNOPSIS
	Displays the last note for a ticket.

	.DESCRIPTION
	Displays the last note for a ticket. If the ticket number is not provided,
	the user is prompted for input. If the ticket number is not found, an error
	is displayed. Double slashes are used to separate lines in a note, and are
	displayed as newlines with this function. The note is also copied to the
	clipboard with some formatting changes.

	.PARAMETER TicketNumber
	The ticket number to display the note for. If this parameter is not provided,
	the user is prompted for input.

	.INPUTS
	System.String. Takes TicketNumber as input.

	.OUTPUTS
	System.String. Returns TicketNumber as output if not the last part of a
	pipeline.

	.EXAMPLE
	PS> Get-LastNote INC012345

	.EXAMPLE
	PS> Add-Note INC012345 "Turned it off and on again." | Get-LastNote
	#>
	[CmdletBinding()]
	param(
		[Parameter(Position=0, ValueFromPipeline=$true)][String] $TicketNumber
	)

	Begin {
		if (!($PSBoundParameters.ContainsKey('TicketNumber'))) {
			try {
				$TicketNumber = @(Get-LastArgs)
			} catch {
				$TicketNumber = Read-Host "Ticket"
			}
		}
	}

	Process {
		$TicketText = helper $TicketNumber
		if (!($TicketText)) {
			Write-Error "Ticket $TicketNumber not found."
			return
		}
		if ($TicketText.Length -eq 0) {
			return
		}

		Write-Host
		if ($TicketText -is [Array]) {
			$DisplayText = $TicketText[-1] -Split '(?<= )// '
			$DisplayText = Format-Wordwrap $DisplayText
			foreach ($line in $DisplayText) {
				Write-Host "    $line"
			}
			$TicketText[-1] = $TicketText[-1] -Replace ('^\d{4}-\d{2}-\d{2} \d{2}:\d{2}: ','')
			$TicketText[-1] = $TicketText[-1] -Replace ("^\[($($TNConfig.subprefixes -join '|'))\d+\] ", '')
			$TicketText[-1] = $TicketText[-1] -Replace ('(?<= )// ', "`n")
			try {
				Set-Clipboard $TicketText[-1]
			} catch { }
		} elseif ($TicketText -is [String]) {
			$DisplayText = $TicketText -Split '(?<= )// '
			$DisplayText = Format-Wordwrap $DisplayText
			foreach ($line in $DisplayText) {
				Write-Host "    $line"
			}
			$TicketText = $TicketText -Replace ('^\d{4}-\d{2}-\d{2} \d{2}:\d{2}: ','')
			$TicketText = $TicketText -Replace ("^\[($($TNConfig.subprefixes -join '|'))\d+\] ", '')
			$TicketText = $TicketText -Replace ('(?<= )// ', "`n")
			try {
				Set-Clipboard $TicketText
			} catch { }
		}
		Write-Host
		if ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength) {
			$TicketNumber
		}
	}

	End {}
}

Export-ModuleMember -Function Get-Note, Get-LastNote
