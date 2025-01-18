function Get-LastArgs {
	$lastHistory = (Get-History -Count 1)
	$lastCommand = $lastHistory.CommandLine
	$errors = [System.Management.Automation.PSParseError[]]@()

	[System.Management.Automation.PSParser]::Tokenize($lastCommand, [ref]$errors) `
	| Where-Object { $_.type -eq 'CommandArgument' } `
	| Select-Object -ExpandProperty content
}
