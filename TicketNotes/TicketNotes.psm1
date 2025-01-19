$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

foreach($import in @( $Public + $Private )) {
	try {
		. $import.FullName
	} catch {
		Write-Error -Message "Failed to import function $($import.FullName): $_"
	}
}

Export-ModuleMember -Function $Public.Basename

if (!(Test-Path "$PSScriptRoot\config.json")) {
	$confirm = Read-Host "[TicketNotes] A configuration file was not found. Would you like to create one? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Config "$PSScriptRoot\config.json"
	} else {
		Throw "[TicketNotes] A configuration file is required to run this module."
	}
}

try {
	$script:TNConfig = (Get-Content "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json)
} catch {
	Throw "[TicketNotes] Error loading configuration file '$PSScriptRoot\config.json'`nPlease check the file, or delete it and re-import this module to generate a default configuration."
}

if (!(Test-Path $TNConfig.directory.root)) {
	$confirm = Read-Host "[TicketNotes] The root directory $($TNConfig.directory.root) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path $TNConfig.directory.root -ItemType Directory
	} else {
		Throw "[TicketNotes] The root directory $($TNConfig.directory.root) is required to run this module."
	}
}

if (!(Test-Path "$($TNConfig.directory.root)\$($TNConfig.directory.daily)")) {
	$confirm = Read-Host "[TicketNotes] The daily directory $($TNConfig.directory.daily) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path "$($TNConfig.directory.root)\$($TNConfig.directory.daily)" -ItemType Directory
	} else {
		Throw "[TicketNotes] The daily directory $($TNConfig.directory.daily) is required to run this module."
	}
}

if (!(Test-Path "$($TNConfig.directory.root)\$($TNConfig.directory.ticket)")) {
	$confirm = Read-Host "[TicketNotes] The ticket directory $($TNConfig.directory.ticket) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path "$($TNConfig.directory.root)\$($TNConfig.directory.ticket)" -ItemType Directory
	} else {
		Throw "[TicketNotes] The ticket directory $($TNConfig.directory.ticket) is required to run this module."
	}
}

if (!(Test-Path "$($TNConfig.directory.root)\$($TNConfig.directory.archive)")) {
	$confirm = Read-Host "[TicketNotes] The archive directory $($TNConfig.directory.archive) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path "$($TNConfig.directory.root)\$($TNConfig.directory.archive)" -ItemType Directory
	} else {
		Throw "[TicketNotes] The archive directory $($TNConfig.directory.archive) is required to run this module."
	}
}
