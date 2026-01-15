# ===============================================
# QR code generation utilities - Specialized modules
# WiFi, Contact, Calendar, Location, Crypto, and TOTP QR codes
# ===============================================
# PSScriptAnalyzer suppressions:
# - PSAvoidUsingPlainTextForPassword: WiFi $Password parameters use String type because
#   they are network credentials for QR code encoding (not user authentication).
#   The password is encoded into a QR code string format, requiring String type.

<#
.SYNOPSIS
    Initializes specialized QR code generation functions.
.DESCRIPTION
    Sets up internal functions for generating specialized QR codes (WiFi, Contact, Calendar, Location, Crypto, TOTP).
    This function is called automatically by Initialize-DevTools-QrCode.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and qrcode package.
#>
function Initialize-DevTools-QrCode-Specialized {
    # WiFi QR Code Generator
    # PSScriptAnalyzer Warning Suppression: $Password parameter uses String type (not SecureString/PSCredential)
    # Rationale: This is a WiFi network password for QR code encoding, not user authentication.
    # The password is encoded into a QR code string format (WIFI:T:WPA;S:SSID;P:Password;H:false;;),
    # which requires String type. Using SecureString/PSCredential would be inappropriate here as
    # the password must be converted to plain text for QR code generation.
    Set-Item -Path Function:Global:_New-QrCodeWiFi -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Ssid,
            [Parameter(Mandatory)]
            [string]$Password,  # PSScriptAnalyzer: String type required for QR code encoding
            [ValidateSet('WPA', 'WEP', 'nopass')]
            [string]$Security = 'WPA',
            [string]$Hidden = 'false',
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use QR code generation."
            }
            $nodeScript = @"
try {
    const QRCode = require('qrcode');
    const fs = require('fs');
    const wifiString = process.argv[1];
    const outputPath = process.argv[2];
    const options = JSON.parse(process.argv[3]);
    QRCode.toFile(outputPath, wifiString, options, (err) => {
        if (err) {
            console.error('Error:', err.message);
            process.exit(1);
        }
    });
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: qrcode package is not installed. Install it with: npm install -g qrcode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            # Format: WIFI:T:WPA;S:mynetwork;P:mypass;;
            $wifiString = "WIFI:T:$Security;S:$Ssid;P:$Password;H:$Hidden;;"
            $options = @{
                width                = $Size
                errorCorrectionLevel = $ErrorCorrectionLevel
            } | ConvertTo-Json -Compress

            if (-not $OutputPath) {
                $OutputPath = Join-Path (Get-Location) "wifi-$Ssid.png"
            }

            $tempScript = Join-Path $env:TEMP "qrcode-wifi-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $wifiString, $OutputPath, $options
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                Write-Host "WiFi QR code generated: $OutputPath" -ForegroundColor Green
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.wifi' -Context @{}
            }
            else {
                Write-Error "Failed to generate WiFi QR code: $_"
            }
        }
    } -Force

    # Contact QR Code Generator (vCard)
    Set-Item -Path Function:Global:_New-QrCodeContact -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Name,
            [string]$Phone,
            [string]$Email,
            [string]$Organization,
            [string]$Url,
            [string]$Address,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use QR code generation."
            }
            $nodeScript = @"
try {
    const QRCode = require('qrcode');
    const fs = require('fs');
    const vcard = process.argv[1];
    const outputPath = process.argv[2];
    const options = JSON.parse(process.argv[3]);
    QRCode.toFile(outputPath, vcard, options, (err) => {
        if (err) {
            console.error('Error:', err.message);
            process.exit(1);
        }
    });
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: qrcode package is not installed. Install it with: npm install -g qrcode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            # Build vCard format
            $vcardLines = @("BEGIN:VCARD", "VERSION:3.0", "FN:$Name")
            if ($Phone) { $vcardLines += "TEL:$Phone" }
            if ($Email) { $vcardLines += "EMAIL:$Email" }
            if ($Organization) { $vcardLines += "ORG:$Organization" }
            if ($Url) { $vcardLines += "URL:$Url" }
            if ($Address) { $vcardLines += "ADR:;;$Address;;;;" }
            $vcardLines += "END:VCARD"
            $vcardString = $vcardLines -join "`r`n"

            $options = @{
                width                = $Size
                errorCorrectionLevel = $ErrorCorrectionLevel
            } | ConvertTo-Json -Compress

            if (-not $OutputPath) {
                $safeName = $Name -replace '[^\w\s-]', '' -replace '\s+', '-'
                $OutputPath = Join-Path (Get-Location) "contact-$safeName.png"
            }

            $tempScript = Join-Path $env:TEMP "qrcode-contact-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $vcardString, $OutputPath, $options
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                Write-Host "Contact QR code generated: $OutputPath" -ForegroundColor Green
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.contact' -Context @{}
            }
            else {
                Write-Error "Failed to generate contact QR code: $_"
            }
        }
    } -Force

    # Calendar Event QR Code Generator (iCal format)
    Set-Item -Path Function:Global:_New-QrCodeCalendar -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Title,
            [Parameter(Mandatory)]
            [DateTime]$StartTime,
            [DateTime]$EndTime,
            [string]$Location,
            [string]$Description,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use QR code generation."
            }
            $nodeScript = @"
try {
    const QRCode = require('qrcode');
    const fs = require('fs');
    const ical = process.argv[1];
    const outputPath = process.argv[2];
    const options = JSON.parse(process.argv[3]);
    QRCode.toFile(outputPath, ical, options, (err) => {
        if (err) {
            console.error('Error:', err.message);
            process.exit(1);
        }
    });
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: qrcode package is not installed. Install it with: npm install -g qrcode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            # Build iCal format
            $startStr = $StartTime.ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
            $endStr = $EndTime.ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
            $nowStr = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")
            $uid = [System.Guid]::NewGuid().ToString()
            
            $icalLines = @(
                "BEGIN:VCALENDAR",
                "VERSION:2.0",
                "PRODID:-//QR Code Generator//EN",
                "BEGIN:VEVENT",
                "UID:$uid",
                "DTSTAMP:$nowStr",
                "DTSTART:$startStr",
                "DTEND:$endStr",
                "SUMMARY:$Title"
            )
            if ($Location) { $icalLines += "LOCATION:$Location" }
            if ($Description) { $icalLines += "DESCRIPTION:$Description" }
            $icalLines += @("END:VEVENT", "END:VCALENDAR")
            $icalString = $icalLines -join "`r`n"

            $options = @{
                width                = $Size
                errorCorrectionLevel = $ErrorCorrectionLevel
            } | ConvertTo-Json -Compress

            if (-not $OutputPath) {
                $safeTitle = $Title -replace '[^\w\s-]', '' -replace '\s+', '-'
                $OutputPath = Join-Path (Get-Location) "calendar-$safeTitle.png"
            }

            $tempScript = Join-Path $env:TEMP "qrcode-calendar-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $icalString, $OutputPath, $options
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                Write-Host "Calendar QR code generated: $OutputPath" -ForegroundColor Green
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.calendar' -Context @{}
            }
            else {
                Write-Error "Failed to generate calendar QR code: $_"
            }
        }
    } -Force

    # Geolocation QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeLocation -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Latitude,
            [Parameter(Mandatory)]
            [double]$Longitude,
            [double]$Altitude,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            # Format: geo:lat,lon or geo:lat,lon,altitude
            $geoString = if ($Altitude) {
                "geo:$Latitude,$Longitude,$Altitude"
            }
            else {
                "geo:$Latitude,$Longitude"
            }
            $params = @{
                Data                 = $geoString
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $params.OutputPath = Join-Path (Get-Location) "location-$Latitude,$Longitude.png"
            }
            _New-QrCode @params
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.location' -Context @{}
            }
            else {
                Write-Error "Failed to generate location QR code: $_"
            }
        }
    } -Force

    # Cryptocurrency Payment QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeCrypto -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Address,
            [ValidateSet('bitcoin', 'ethereum', 'litecoin', 'bitcoincash', 'monero', 'custom')]
            [string]$Currency = 'bitcoin',
            [double]$Amount,
            [string]$Label,
            [string]$Message,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            $cryptoString = switch ($Currency.ToLower()) {
                'bitcoin' { "bitcoin:${Address}" }
                'ethereum' { "ethereum:${Address}" }
                'litecoin' { "litecoin:${Address}" }
                'bitcoincash' { "bitcoincash:${Address}" }
                'monero' { "monero:${Address}" }
                default { "${Currency}:${Address}" }
            }
            
            $queryParams = @()
            if ($Amount -gt 0) {
                $queryParams += "amount=$Amount"
            }
            if ($Label) {
                $queryParams += "label=$([System.Uri]::EscapeDataString($Label))"
            }
            if ($Message) {
                $queryParams += "message=$([System.Uri]::EscapeDataString($Message))"
            }
            if ($queryParams.Count -gt 0) {
                $cryptoString += "?$($queryParams -join '&')"
            }
            
            $params = @{
                Data                 = $cryptoString
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $params.OutputPath = Join-Path (Get-Location) "crypto-$Currency.png"
            }
            _New-QrCode @params
        }
        catch {
            Write-Error "Failed to generate cryptocurrency QR code: $_"
        }
    } -Force

    # TOTP/2FA QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeTotp -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Secret,
            [Parameter(Mandatory)]
            [string]$Issuer,
            [Parameter(Mandatory)]
            [string]$AccountName,
            [ValidateSet('SHA1', 'SHA256', 'SHA512')]
            [string]$Algorithm = 'SHA1',
            [int]$Digits = 6,
            [int]$Period = 30,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            # Format: otpauth://totp/Issuer:AccountName?secret=Secret&issuer=Issuer&algorithm=Algorithm&digits=Digits&period=Period
            $label = "$Issuer`:$AccountName"
            $labelEncoded = [System.Uri]::EscapeDataString($label)
            $issuerEncoded = [System.Uri]::EscapeDataString($Issuer)
            
            $totpString = "otpauth://totp/$labelEncoded?secret=$Secret&issuer=$issuerEncoded&algorithm=$Algorithm&digits=$Digits&period=$Period"
            
            $params = @{
                Data                 = $totpString
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $safeAccount = $AccountName -replace '[^\w\.-]', ''
                $params.OutputPath = Join-Path (Get-Location) "totp-$safeAccount.png"
            }
            _New-QrCode @params
        }
        catch {
            Write-Error "Failed to generate TOTP QR code: $_"
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Generates a WiFi network QR code.
.DESCRIPTION
    Creates a QR code that can be scanned to automatically connect to a WiFi network.
    Requires Node.js and qrcode package.
.PARAMETER Ssid
    The WiFi network name (SSID). This parameter is mandatory.
.PARAMETER Password
    The WiFi network password. This parameter is mandatory.
.PARAMETER Security
    The security type: WPA, WEP, or nopass. Default is WPA.
.PARAMETER Hidden
    Whether the network is hidden. Default is false.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to wifi-{SSID}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeWiFi -Ssid "MyNetwork" -Password "MyPassword123"
    Generates a WiFi QR code that can be scanned to connect to the network.
#>
# PSScriptAnalyzer Warning Suppression: $Password parameter uses String type (not SecureString/PSCredential)
# Rationale: This is a WiFi network password for QR code encoding, not user authentication.
# The password is encoded into a QR code string format (WIFI:T:WPA;S:SSID;P:Password;H:false;;),
# which requires String type. Using SecureString/PSCredential would be inappropriate here as
# the password must be converted to plain text for QR code generation.
function New-QrCodeWiFi {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', 'Password', Justification = 'WiFi network password for QR code encoding, not user authentication. String type required for QR code string format.')]
    param(
        [Parameter(Mandatory)]
        [string]$Ssid,
        [Parameter(Mandatory)]
        [string]$Password,
        [ValidateSet('WPA', 'WEP', 'nopass')]
        [string]$Security = 'WPA',
        [string]$Hidden = 'false',
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeWiFi @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a contact card (vCard) QR code.
.DESCRIPTION
    Creates a QR code containing contact information in vCard format that can be scanned to add to contacts.
    Requires Node.js and qrcode package.
.PARAMETER Name
    The contact's full name. This parameter is mandatory.
.PARAMETER Phone
    The contact's phone number.
.PARAMETER Email
    The contact's email address.
.PARAMETER Organization
    The contact's organization or company.
.PARAMETER Url
    The contact's website URL.
.PARAMETER Address
    The contact's address.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to contact-{Name}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeContact -Name "John Doe" -Phone "+1234567890" -Email "john@example.com"
    Generates a contact QR code with name, phone, and email.
#>
function New-QrCodeContact {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Phone,
        [string]$Email,
        [string]$Organization,
        [string]$Url,
        [string]$Address,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeContact @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a calendar event QR code.
.DESCRIPTION
    Creates a QR code containing a calendar event in iCal format that can be scanned to add to calendar.
    Requires Node.js and qrcode package.
.PARAMETER Title
    The event title. This parameter is mandatory.
.PARAMETER StartTime
    The event start time. This parameter is mandatory.
.PARAMETER EndTime
    The event end time. This parameter is mandatory.
.PARAMETER Location
    Optional event location.
.PARAMETER Description
    Optional event description.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to calendar-{title}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    $start = Get-Date "2024-12-25 10:00"
    $end = Get-Date "2024-12-25 12:00"
    New-QrCodeCalendar -Title "Meeting" -StartTime $start -EndTime $end -Location "Conference Room"
    Generates a calendar event QR code.
#>
function New-QrCodeCalendar {
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [DateTime]$StartTime,
        [Parameter(Mandatory)]
        [DateTime]$EndTime,
        [string]$Location,
        [string]$Description,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeCalendar @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a geolocation QR code.
.DESCRIPTION
    Creates a QR code containing GPS coordinates that can be scanned to open in maps.
    Requires Node.js and qrcode package.
.PARAMETER Latitude
    The latitude coordinate. This parameter is mandatory.
.PARAMETER Longitude
    The longitude coordinate. This parameter is mandatory.
.PARAMETER Altitude
    Optional altitude in meters.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to location-{lat},{lon}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeLocation -Latitude 40.7128 -Longitude -74.0060
    Generates a geolocation QR code for New York City.
#>
function New-QrCodeLocation {
    param(
        [Parameter(Mandatory)]
        [double]$Latitude,
        [Parameter(Mandatory)]
        [double]$Longitude,
        [double]$Altitude,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeLocation @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a cryptocurrency payment QR code.
.DESCRIPTION
    Creates a QR code for cryptocurrency payments that can be scanned by wallet apps.
    Requires Node.js and qrcode package.
.PARAMETER Address
    The cryptocurrency wallet address. This parameter is mandatory.
.PARAMETER Currency
    The cryptocurrency type: bitcoin, ethereum, litecoin, bitcoincash, monero, or custom. Default is bitcoin.
.PARAMETER Amount
    Optional payment amount.
.PARAMETER Label
    Optional payment label/description.
.PARAMETER Message
    Optional payment message.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to crypto-{currency}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeCrypto -Address "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" -Currency bitcoin -Amount 0.001
    Generates a Bitcoin payment QR code.
#>
function New-QrCodeCrypto {
    param(
        [Parameter(Mandatory)]
        [string]$Address,
        [ValidateSet('bitcoin', 'ethereum', 'litecoin', 'bitcoincash', 'monero', 'custom')]
        [string]$Currency = 'bitcoin',
        [double]$Amount,
        [string]$Label,
        [string]$Message,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeCrypto @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a TOTP/2FA QR code.
.DESCRIPTION
    Creates a QR code for Time-based One-Time Password (TOTP) authentication that can be scanned by authenticator apps.
    Requires Node.js and qrcode package.
.PARAMETER Secret
    The TOTP secret key (base32 encoded). This parameter is mandatory.
.PARAMETER Issuer
    The service/issuer name (e.g., "GitHub", "Google"). This parameter is mandatory.
.PARAMETER AccountName
    The account name or username. This parameter is mandatory.
.PARAMETER Algorithm
    The hash algorithm: SHA1, SHA256, or SHA512. Default is SHA1.
.PARAMETER Digits
    The number of digits in the TOTP code. Default is 6.
.PARAMETER Period
    The time period in seconds. Default is 30.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to totp-{account}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeTotp -Secret "JBSWY3DPEHPK3PXP" -Issuer "GitHub" -AccountName "user@example.com"
    Generates a TOTP QR code for GitHub authentication.
#>
function New-QrCodeTotp {
    param(
        [Parameter(Mandatory)]
        [string]$Secret,
        [Parameter(Mandatory)]
        [string]$Issuer,
        [Parameter(Mandatory)]
        [string]$AccountName,
        [ValidateSet('SHA1', 'SHA256', 'SHA512')]
        [string]$Algorithm = 'SHA1',
        [int]$Digits = 6,
        [int]$Period = 30,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeTotp @PSBoundParameters
}

# Aliases
Set-Alias -Name qrcode-wifi -Value New-QrCodeWiFi -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-contact -Value New-QrCodeContact -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-calendar -Value New-QrCodeCalendar -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-location -Value New-QrCodeLocation -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-crypto -Value New-QrCodeCrypto -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-totp -Value New-QrCodeTotp -ErrorAction SilentlyContinue

