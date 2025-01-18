function Format-Wordwrap {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[Object[]] $chunk
	)

	Process {
		$lines = @()
		foreach ($line in $chunk) {
			$str = ''
			$counter = 0
			$line -split '\s+' | Foreach-Object {
				if ($_.Length -gt ($Host.UI.RawUI.BufferSize.Width - 4) -and $str -eq '') {
					$lines += ,$_.trim()
					continue
				}
				$counter += $_.Length + 1
				if ($counter -gt ($Host.UI.RawUI.BufferSize.Width - 4)) {
					$lines += ,$str.trim()
					$str = ''
					$counter = $_.Length + 1
				}
				$str = "$str$_ "
			}
			$lines += ,$str.trim()
		}
		$lines
	}
}
