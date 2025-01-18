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
	$confirm = Read-Host "[SimpleTicket] A configuration file was not found. Would you like to create one? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Config "$PSScriptRoot\config.json"
	} else {
		Throw "[SimpleTicket] A configuration file is required to run this module."
	}
}

try {
	$script:STConfig = (Get-Content "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json)
} catch {
	Throw "[SimpleTicket] Error loading configuration file '$PSScriptRoot\config.json'`nPlease check the file, or delete it and re-import this module to generate a default configuration."
}

if (!(Test-Path $STConfig.directory.root)) {
	$confirm = Read-Host "[SimpleTicket] The root directory $($STConfig.directory.root) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path $STConfig.directory.root -ItemType Directory
	} else {
		Throw "[SimpleTicket] The root directory $($STConfig.directory.root) is required to run this module."
	}
}

if (!(Test-Path "$($STConfig.directory.root)\$($STConfig.directory.daily)")) {
	$confirm = Read-Host "[SimpleTicket] The daily directory $($STConfig.directory.daily) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path "$($STConfig.directory.root)\$($STConfig.directory.daily)" -ItemType Directory
	} else {
		Throw "[SimpleTicket] The daily directory $($STConfig.directory.daily) is required to run this module."
	}
}

if (!(Test-Path "$($STConfig.directory.root)\$($STConfig.directory.ticket)")) {
	$confirm = Read-Host "[SimpleTicket] The ticket directory $($STConfig.directory.ticket) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path "$($STConfig.directory.root)\$($STConfig.directory.ticket)" -ItemType Directory
	} else {
		Throw "[SimpleTicket] The ticket directory $($STConfig.directory.ticket) is required to run this module."
	}
}

if (!(Test-Path "$($STConfig.directory.root)\$($STConfig.directory.archive)")) {
	$confirm = Read-Host "[SimpleTicket] The archive directory $($STConfig.directory.archive) was not found. Would you like to create it? y/N"
	if ($confirm.ToLower() -eq "y") {
		New-Item -Path "$($STConfig.directory.root)\$($STConfig.directory.archive)" -ItemType Directory
	} else {
		Throw "[SimpleTicket] The archive directory $($STConfig.directory.archive) is required to run this module."
	}
}
