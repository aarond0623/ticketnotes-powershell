function issubticket($ticket) {
	$TicketNumber -match "^($($TNConfig.subprefixes -join '|'))(\d+)$"
}

function findparent($subticket, $directory) {
	$prefixes = $TNConfig.prefixes | Foreach-Object { $_ + "*" }
	(Get-ChildItem -Path $directory -Recurse -Include @($prefixes) -Filter "*.txt" `
	| Select-String "\[$SubTicket\]" `
	| Select-Object Path -First 1 `
	| Get-Item).BaseName
}

function createheader($TicketNumber) {
	$user         = Read-Host "User's name"
	$location     = Read-Host "   Location"
	$phone        = Read-host "    Phone #"
	$device       = Read-Host "     Device"
	$description  = Read-Host "Description"
	$phone = $phone -replace "[^0-9]"
	if ($phone.Length -ge 11) {
		$phone = $phone.Substring(0, 1) + "-" + $phone.Substring(1, 3) + "-" + $phone.Substring(4, 3) + "-" + $phone.Substring(7)
	} elseif ($phone.Length -ge 10) {
		$phone = $phone.Substring(0, 3) + "-" + $phone.Substring(3, 3) + "-" + $phone.Substring(6)
	} elseif ($phone.Length -ge 7) {
		$phone = $phone.Substring(0, 3) + "-" + $phone.Substring(3)
	}
	"$($TicketNumber):" + (&{if($user) {" $user"}}) + (&{if($location) {" @ $location"}}) + (&{if($phone) {" ($phone)"}}) + (&{if($device) {"; $device"}}) + (&{if($description) {" - $description"}})
}
