function Search-Note {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)][String] $Search,
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
		$FileList = Get-ChildItem -Path $notesdir -Recurse -Include "*.txt"
		foreach ($term in $Search) {
			$FileList = $FileList | Where-Object { $_ | Select-String -Pattern $term }
		}
		foreach ($File in $FileList) {
			$Folder = Split-Path (Split-Path $File.Fullname -Parent) -Leaf
			if (!$Daily -and $File.BaseName -match "\d{4}-\d{2}-\d{2}") {
				continue
			}
			if (!$Daily -and $Old -and $File.BaseName -match "\d{4}_daily") {
				continue
			}
			if (!$Old -and $File.BaseName -match "\d{4}_") {
				continue
			}
			Write-Host -ForegroundColor Blue "`n    $folder\$($File.BaseName):"
			$Results = Select-String -Pattern $Search -Path $File.FullName
			foreach ($result in $results) {
				if ($Old -and $File.BaseName -match '\d{4}_') {
					$skip = $False
					foreach ($term in $search) {
						if ($result -notmatch $term) {
							$skip = $True
							break
						}
					}
					if ($skip) {
						continue
					}
				}
				$result = Format-Wordwrap $result.Line
				foreach ($line in $result) {
					Write-Host -NoNewLine "    "
					foreach ($word in $line -split '(\s+)') {
						if ($word -match "$($Search -join "|")") {
							Write-Host -ForegroundColor Yellow -NoNewLine $word
						} else {
							Write-Host -NoNewLine $word
						}
					}
					Write-Host
				}
			}
		}
		Write-Host
	}

	End {}
}
