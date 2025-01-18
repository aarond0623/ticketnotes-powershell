function New-Config($filename) {
	# Default configuration
	$config = [PSCustomObject]@{
		"editor" = @{
			"command" = "notepad"
			"args" = ""
		}
		"directory" = @{
			"root" = "$([Environment]::GetFolderPath("MyDocuments"))\Notes"
			"daily" = "daily"
			"ticket" = "ticket"
			"archive" = "archive"
		}
	}

	$config | ConvertTo-Json | Set-Content -Path $filename
}
