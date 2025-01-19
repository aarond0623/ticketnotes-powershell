function New-Config($filename) {
	# Default configuration
	if ($IsLinux) {
		$editor = "vim"
		$editorArgs = "-o"
		$root = "$($Env:HOME)/Documents/Notes"
	} else {
		$editor = "notepad"
		$editorArgs = ""
		$root = "$([Environment]::GetFolderPath("MyDocuments"))\Notes"
	}
	$config = [PSCustomObject]@{
		"editor" = @{
			"command" = $editor
			"args" = $editorArgs
		}
		"directory" = @{
			"root" = $root
			"daily" = "daily"
			"ticket" = "ticket"
			"archive" = "archive"
		}
		"prefixes" = @(
			"INC"
			"REQ"
		)
		"subprefixes" = @(
			"RITM"
		)
	}

	$config | ConvertTo-Json | Set-Content -Path $filename
}
