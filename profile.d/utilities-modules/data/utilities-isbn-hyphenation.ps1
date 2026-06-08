# ===============================================
# ISBN registrant-aware hyphenation helpers
# ===============================================

function script:Get-IsbnRegistrantLengthRanges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$GroupNumber
    )

    switch ($GroupNumber) {
        0 {
            return @(
                @{ Min = 0; Max = 19; Length = 2 }
                @{ Min = 20; Max = 699; Length = 3 }
                @{ Min = 7000; Max = 8499; Length = 4 }
                @{ Min = 85000; Max = 89999; Length = 5 }
                @{ Min = 900000; Max = 949999; Length = 6 }
                @{ Min = 9500000; Max = 9999999; Length = 7 }
            )
        }
        1 {
            return @(
                @{ Min = 0; Max = 9; Length = 2 }
                @{ Min = 10; Max = 39; Length = 3 }
                @{ Min = 400; Max = 849; Length = 4 }
                @{ Min = 8500; Max = 8999; Length = 5 }
                @{ Min = 90000; Max = 94999; Length = 6 }
                @{ Min = 950000; Max = 999999; Length = 7 }
            )
        }
        default {
            return @(
                @{ Min = 0; Max = 19; Length = 2 }
                @{ Min = 20; Max = 699; Length = 3 }
                @{ Min = 7000; Max = 8499; Length = 4 }
                @{ Min = 85000; Max = 89999; Length = 5 }
                @{ Min = 900000; Max = 949999; Length = 6 }
                @{ Min = 9500000; Max = 9999999; Length = 7 }
            )
        }
    }
}

function script:Get-IsbnRegistrantElementLength {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [int]$GroupNumber,

        [Parameter(Mandatory)]
        [string]$DigitsAfterGroup
    )

    if ($DigitsAfterGroup -notmatch '^\d+$') {
        return -1
    }

    $ranges = Get-IsbnRegistrantLengthRanges -GroupNumber $GroupNumber
    foreach ($range in $ranges) {
        $maxLength = [Math]::Max($range.Min.ToString().Length, $range.Max.ToString().Length)
        if ($DigitsAfterGroup.Length -lt $maxLength) {
            $probe = $DigitsAfterGroup.PadRight($maxLength, '0')
        }
        else {
            $probe = $DigitsAfterGroup.Substring(0, $maxLength)
        }

        $value = [int]$probe
        if ($value -ge $range.Min -and $value -le $range.Max) {
            return [int]$range.Length
        }
    }

    return -1
}

function script:Format-IsbnRegistrantHyphenated {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Digits
    )

    if ($Digits.Length -eq 13 -and $Digits -match '^(97[89])(\d{10})$') {
        $prefix = $Matches[1]
        $body = $Matches[2]
        $groupDigit = [int]$body.Substring(0, 1)
        $afterGroup = $body.Substring(1, 9)
        $registrantLength = Get-IsbnRegistrantElementLength -GroupNumber $groupDigit -DigitsAfterGroup $afterGroup

        if ($registrantLength -gt 0 -and ($registrantLength + 1) -lt $afterGroup.Length) {
            $registrant = $afterGroup.Substring(0, $registrantLength)
            $publication = $afterGroup.Substring($registrantLength, $afterGroup.Length - $registrantLength - 1)
            $check = $afterGroup.Substring($afterGroup.Length - 1, 1)
            return "$prefix-$groupDigit-$registrant-$publication-$check"
        }
    }

    if ($Digits.Length -eq 10 -and $Digits -match '^(\d)(\d{8}[\dX])$') {
        $groupDigit = [int]$Matches[1]
        $afterGroup = $Matches[2].Substring(0, 8)
        $check = $Matches[2].Substring(8, 1)
        $registrantLength = Get-IsbnRegistrantElementLength -GroupNumber $groupDigit -DigitsAfterGroup $afterGroup

        if ($registrantLength -gt 0 -and ($registrantLength + 1) -lt $afterGroup.Length) {
            $registrant = $afterGroup.Substring(0, $registrantLength)
            $publication = $afterGroup.Substring($registrantLength, $afterGroup.Length - $registrantLength)
            return "$groupDigit-$registrant-$publication-$check"
        }
    }

    return $null
}
