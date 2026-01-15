# ===============================================
# QR code generation utilities - Communication modules
# URL, SMS, Email, and Phone QR codes
# ===============================================

<#
.SYNOPSIS
    Initializes communication-specific QR code generation functions.
.DESCRIPTION
    Sets up internal functions for generating QR codes for communication (URL, SMS, Email, Phone).
    This function is called automatically by Initialize-DevTools-QrCode.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and qrcode package.
#>
function Initialize-DevTools-QrCode-Communication {
    # URL QR Code Generator with title
    Set-Item -Path Function:Global:_New-QrCodeUrl -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Url,
            [string]$Title,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            if (-not $Url.StartsWith('http://') -and -not $Url.StartsWith('https://')) {
                $Url = "https://$Url"
            }
            if ($Title) {
                $data = $Url
            }
            else {
                $data = $Url
            }
            $params = @{
                Data                 = $data
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $uri = [System.Uri]$Url
                $hostName = $uri.Host -replace '[^\w\.-]', ''
                $params.OutputPath = Join-Path (Get-Location) "url-$hostName.png"
            }
            _New-QrCode @params
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.url' -Context @{}
            }
            else {
                Write-Error "Failed to generate URL QR code: $_"
            }
        }
    } -Force

    # SMS/Text Message QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeSms -Value {
        param(
            [Parameter(Mandatory)]
            [string]$PhoneNumber,
            [string]$Message,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            # Format: SMSTO:number:message
            $smsString = if ($Message) {
                "SMSTO:${PhoneNumber}:${Message}"
            }
            else {
                "SMSTO:${PhoneNumber}:"
            }
            $params = @{
                Data                 = $smsString
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $safePhone = $PhoneNumber -replace '[^\d]', ''
                $params.OutputPath = Join-Path (Get-Location) "sms-$safePhone.png"
            }
            _New-QrCode @params
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.sms' -Context @{}
            }
            else {
                Write-Error "Failed to generate SMS QR code: $_"
            }
        }
    } -Force

    # Email QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeEmail -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Email,
            [string]$Subject,
            [string]$Body,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            # Format: mailto:email?subject=Subject&body=Body
            $emailString = "mailto:$Email"
            $queryParams = @()
            if ($Subject) {
                $queryParams += "subject=$([System.Uri]::EscapeDataString($Subject))"
            }
            if ($Body) {
                $queryParams += "body=$([System.Uri]::EscapeDataString($Body))"
            }
            if ($queryParams.Count -gt 0) {
                $emailString += "?$($queryParams -join '&')"
            }
            $params = @{
                Data                 = $emailString
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $safeEmail = $Email -replace '[^\w\.-]', ''
                $params.OutputPath = Join-Path (Get-Location) "email-$safeEmail.png"
            }
            _New-QrCode @params
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.email' -Context @{}
            }
            else {
                Write-Error "Failed to generate email QR code: $_"
            }
        }
    } -Force

    # Phone Call QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodePhone -Value {
        param(
            [Parameter(Mandatory)]
            [string]$PhoneNumber,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M'
        )
        try {
            # Format: tel:number
            $phoneString = "tel:$PhoneNumber"
            $params = @{
                Data                 = $phoneString
                Size                 = $Size
                ErrorCorrectionLevel = $ErrorCorrectionLevel
            }
            if ($OutputPath) {
                $params.OutputPath = $OutputPath
            }
            else {
                $safePhone = $PhoneNumber -replace '[^\d]', ''
                $params.OutputPath = Join-Path (Get-Location) "phone-$safePhone.png"
            }
            _New-QrCode @params
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.phone' -Context @{}
            }
            else {
                Write-Error "Failed to generate phone QR code: $_"
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Generates a URL QR code.
.DESCRIPTION
    Creates a QR code for a URL. Automatically adds https:// if no protocol is specified.
    Requires Node.js and qrcode package.
.PARAMETER Url
    The URL to encode. This parameter is mandatory.
.PARAMETER Title
    Optional title for the URL (not encoded in QR code, for reference only).
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to url-{hostname}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeUrl -Url "example.com"
    Generates a QR code for https://example.com.
.EXAMPLE
    New-QrCodeUrl -Url "https://example.com" -Title "My Website"
    Generates a QR code for the URL with a title reference.
#>
function New-QrCodeUrl {
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [string]$Title,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeUrl @PSBoundParameters
}

<#
.SYNOPSIS
    Generates an SMS/text message QR code.
.DESCRIPTION
    Creates a QR code that can be scanned to send an SMS message.
    Requires Node.js and qrcode package.
.PARAMETER PhoneNumber
    The phone number to send the SMS to. This parameter is mandatory.
.PARAMETER Message
    Optional pre-filled message text.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to sms-{phone}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeSms -PhoneNumber "+1234567890" -Message "Hello!"
    Generates an SMS QR code with a pre-filled message.
#>
function New-QrCodeSms {
    param(
        [Parameter(Mandatory)]
        [string]$PhoneNumber,
        [string]$Message,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeSms @PSBoundParameters
}

<#
.SYNOPSIS
    Generates an email QR code.
.DESCRIPTION
    Creates a QR code that can be scanned to compose an email.
    Requires Node.js and qrcode package.
.PARAMETER Email
    The email address. This parameter is mandatory.
.PARAMETER Subject
    Optional email subject.
.PARAMETER Body
    Optional email body text.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to email-{email}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodeEmail -Email "contact@example.com" -Subject "Hello" -Body "Message body"
    Generates an email QR code with subject and body.
#>
function New-QrCodeEmail {
    param(
        [Parameter(Mandatory)]
        [string]$Email,
        [string]$Subject,
        [string]$Body,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeEmail @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a phone call QR code.
.DESCRIPTION
    Creates a QR code that can be scanned to make a phone call.
    Requires Node.js and qrcode package.
.PARAMETER PhoneNumber
    The phone number to call. This parameter is mandatory.
.PARAMETER OutputPath
    The path where the QR code image will be saved. If not specified, defaults to phone-{number}.png in current directory.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.EXAMPLE
    New-QrCodePhone -PhoneNumber "+1234567890"
    Generates a phone call QR code.
#>
function New-QrCodePhone {
    param(
        [Parameter(Mandatory)]
        [string]$PhoneNumber,
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodePhone @PSBoundParameters
}

# Aliases
Set-Alias -Name qrcode-url -Value New-QrCodeUrl -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-sms -Value New-QrCodeSms -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-email -Value New-QrCodeEmail -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-phone -Value New-QrCodePhone -ErrorAction SilentlyContinue

