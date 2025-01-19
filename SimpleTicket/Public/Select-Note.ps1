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

	.INPUTS
	None. Does not accept input from the pipeline.

	.OUTPUTS
	Microsoft.PowerShell.Commands.MatchInfo. Returns a Select-String object if
	not the last part of a pipeline.

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
		Write-Host
		Get-ChildItem -Path $notesdir -Recurse -Filter "*.txt" `
		| Where-Object { $_.BaseName -match $Regex } `
		| Select-String -Pattern $Pattern `
		| Tee-Object -Variable SelectStringResults `
		| Foreach-Object {
			$Folder = Split-Path (Split-Path $_.Path -Parent) -Leaf
			$File = Split-Path $_.Path -Leaf
			Write-Host -ForegroundColor Blue "$Folder\$($File):$($_.LineNumber):"
			$Result = Format-Wordwrap $_.Line
			Foreach ($Line in $Result) {
				Write-Host -NoNewLine "    "
				if ($Line -match "$($Pattern -join "|")") {
					$Line = $Line -split "($($Pattern -join "|"))"
					Foreach ($Part in $Line) {
						if ($Part -match "$($Pattern -join "|")") {
							Write-Host -BackgroundColor Yellow -ForegroundColor Black -NoNewLine $Part
						} else {
							Write-Host -NoNewLine $Part
						}
					}
				} else {
					Write-Host $Line -NoNewLine
				}
				Write-Host
			}
			Write-Host
		}
		if ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength) {
			$SelectStringResults
		}
	}

	End {}
}
