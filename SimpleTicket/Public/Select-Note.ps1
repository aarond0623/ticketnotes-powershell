function Select-Note {
	<#
	.SYNOPSIS
	Searches notes for a term or terms.

	.DESCRIPTION
	Searches notes for a term or terms. By default, the search is only performed
	on tickets only, and excludes any notes in old files merged with
	Merge-Archive. If the -Daily switch is used, the search is performed on daily
	notes as well. If the -Old switch is used, the search is performed on merged
	notes as well.

	.PARAMETER Pattern
	The term or terms to search for.

	.EXAMPLE
	PS> Select-Note "off and on"

	.EXAMPLE
	PS> Select-Note "off", "on"
	#>
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)][String[]] $Pattern,
		[Switch] $Daily,
		[Switch] $Old
	)

	Begin {
		$notesdir = $STConfig.directory.root
		$ticketdir = "$notesdir\$($STConfig.directory.ticket)"
		$archivedir = "$notesdir\$($STConfig.directory.archive)"
		$dailydir = "$notesdir\$($STConfig.directory.daily)"
	}

	Process {
		$Regex = ($STConfig.prefixes | Foreach-Object { "^$_" }) -join "|"
		if ($Daily) {
			$Regex += "|^\d{4}-\d{2}-\d{2}"
		}
		if ($Old) {
			$Regex += "|^\d{4}_ticket"
		}
		if ($Old -and $Daily) {
			$Regex += "|^\d{4}_daily"
		}
		$FileList = (Get-ChildItem -Path $notesdir -Recurse -Filter "*.txt" `
		| Where-Object { $_.BaseName -match $Regex })
		foreach ($term in $Pattern) {
			$FileList = $FileList | Where-Object { $_ | Select-String -Pattern $term }
		}
		foreach ($File in $FileList) {
			$Folder = Split-Path (Split-Path $File.Fullname -Parent) -Leaf
			Write-Host -ForegroundColor Blue "`n    $folder\$($File.BaseName):"
			$Results = Select-String -Pattern $Pattern -Path $File.FullName
			foreach ($Result in $Results) {
				$Result = Format-Wordwrap $Result.Line
				foreach ($line in $Result) {
					Write-Host -NoNewLine "    "
					if ($line -match "$($Pattern -join "|")") {
						$line = $line -split "($($Pattern -join "|"))"
						foreach ($part in $line) {
							if ($part -match "$($Pattern -join "|")") {
								Write-Host -ForegroundColor Yellow -NoNewLine $part
							} else {
								Write-Host -NoNewLine $part
							}
						}
					} else {
						Write-Host $line
					}
					Write-Host
				}
			}
		}
		Write-Host
	}

	End {}
}
