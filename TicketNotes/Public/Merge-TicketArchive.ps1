function Merge-TicketArchive {
	<#
	.SYNOPSIS
	Merges daily and ticket files into yearly archives.

	.DESCRIPTION
	Merges daily and ticket files into yearly archives. Daily files are merged
	into a single file named YYYY_daily.txt, where YYYY is the year. Ticket files
	are merged into a single file named YYYY_ticket.txt, where YYYY is the year.

	.PARAMETER Year
	The year to merge. If not provided, the user is prompted for input.

	.EXAMPLE
	PS> Merge-TicketArchive 2025
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][Int] $Year
	)
	Begin {
		$notesdir = $TNConfig.directory.root
		$archivedir = "$notesdir\$($TNConfig.directory.archive)"
		$year_archive = "$archivedir\$($Year)_daily.txt"
		$ticket_archive = "$archivedir\$($Year)_ticket.txt"
		try {
			New-Item -Path $year_archive -ItemType File -ErrorAction Stop
		} catch {
			Throw "Failed to create $year_archive"
		}
		try {
			New-Item -Path $ticket_archive -ItemType File -ErrorAction Stop
		} catch {
			Throw "Failed to create $ticket_archive"
		}
	}

	Process {
		# Add all daily files to daily archive
		$filelist = Get-ChildItem -Path $archivedir -Filter "$Year-*-*.txt"
		foreach ($file in $filelist) {
			Add-Content -Path $year_archive -Value "----------------" -Encoding UTF8
			Add-Content -Path $year_archive -Value "" -Encoding UTF8
			Add-Content -Path $year_archive -Value (Get-Content $file.FullName -Encoding UTF8 `
			| Foreach-Object { $file.BaseName + " " + $_ }) -Encoding UTF8
			Add-Content -Path $year_archive -Value "" -Encoding UTF8
		}
		Write-Host "Dailies merged into $year_archive"

		# Add all the ticket files to ticket archive
		$prefixes = $TNConfig.prefixes | Foreach-Object { $_ + "*" }
		$filelist = Get-ChildItem -Path $archivedir -Recurse -Include @($prefixes) -Filter "*.txt"
		foreach ($file in $filelist) {
			Add-Content -Path $ticket_archive -Value "----------------" -Encoding UTF8
			Add-Content -Path $ticket_archive -Value "" -Encoding UTF8
			$tickettext = Get-Content $file.FullName -Encoding UTF8 | Where-Object { $_.trim() -ne "" }
			foreach ($line in $tickettext) {
				if ($line -match "^\d{4}-\d{2}-\d{2} \d{2}:\d{2} ") {
					$line = ($line[0..17] -join '') + "[$($file.BaseName)]" + ($line[17..$line.Length] -join '')
				}
				Add-Content -Path $ticket_archive -Value $line -Encoding UTF8
			}
			Add-Content -Path $ticket_archive -Value "" -Encoding UTF8
		}
		Write-Host "Tickets merged into $ticket_archive"
	}

	End {}
}
