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
