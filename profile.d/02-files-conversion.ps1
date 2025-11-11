# ===============================================
# 02-files-conversion.ps1
# File conversion utilities
# ===============================================

# Lazy bulk initializer for file conversion helpers
<#
.SYNOPSIS
    Initializes file conversion utility functions on first use.
.DESCRIPTION
    Sets up all file conversion utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
if (-not (Test-Path "Function:\\Ensure-FileConversion")) {
    function Ensure-FileConversion {
        # JSON pretty-print
        Set-Item -Path Function:Format-Json -Value {
            param(
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,
                [Parameter(ValueFromRemainingArguments = $true)]
                $fileArgs
            )
            process {
                $rawInput = $null
                try {
                    if ($fileArgs) {
                        $rawInput = Get-Content -Raw -LiteralPath @fileArgs
                        $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                    }
                    elseif ($PSBoundParameters.ContainsKey('InputObject') -and $null -ne $InputObject) {
                        $rawInput = $InputObject
                        $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                    }
                    else {
                        $rawInput = $input | Out-String
                        if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
                            $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to pretty-print JSON: $($_.Exception.Message)"
                    if ($null -ne $rawInput) {
                        Write-Output $rawInput
                    }
                }
            }
        } -Force | Out-Null
        Set-Alias -Name json-pretty -Value Format-Json -ErrorAction SilentlyContinue

        # YAML to JSON
        Set-Item -Path Function:ConvertFrom-Yaml -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) yq eval -o=json @fileArgs } -Force | Out-Null
        Set-Alias -Name yaml-to-json -Value ConvertFrom-Yaml -ErrorAction SilentlyContinue
        # JSON to YAML
        Set-Item -Path Function:ConvertTo-Yaml -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) yq eval -P @fileArgs } -Force | Out-Null
        Set-Alias -Name json-to-yaml -Value ConvertTo-Yaml -ErrorAction SilentlyContinue

        # Base64 encode
        Set-Item -Path Function:ConvertTo-Base64 -Value {
            param([Parameter(ValueFromPipeline = $true)] $InputObject)
            process {
                if ($InputObject -is [string] -and $InputObject.IndexOf([char]0) -eq -1) {
                    try {
                        $resolved = Resolve-Path -LiteralPath $InputObject -ErrorAction Stop
                        return [Convert]::ToBase64String([IO.File]::ReadAllBytes($resolved))
                    }
                    catch {
                        # Treat the value as literal text if it cannot be resolved as a path.
                        Write-Verbose "ConvertTo-Base64 treating input as literal text: $($_.Exception.Message)"
                    }
                }

                if ($InputObject -is [byte[]]) {
                    return [Convert]::ToBase64String($InputObject)
                }

                $text = if ($null -ne $InputObject) { [string]$InputObject } else { [string]::Empty }
                $bytes = [Text.Encoding]::UTF8.GetBytes($text)
                return [Convert]::ToBase64String($bytes)
            }
        } -Force | Out-Null
        Set-Alias -Name to-base64 -Value ConvertTo-Base64 -ErrorAction SilentlyContinue
        # Base64 decode
        Set-Item -Path Function:ConvertFrom-Base64 -Value { param([Parameter(ValueFromPipeline = $true)] $InputObject) process { $s = ($InputObject -join "") -replace '\s+', ''; try { $bytes = [Convert]::FromBase64String($s); [Text.Encoding]::UTF8.GetString($bytes) } catch { Write-Error "Invalid base64 input" } } } -Force | Out-Null
        Set-Alias -Name from-base64 -Value ConvertFrom-Base64 -ErrorAction SilentlyContinue

        # CSV to JSON
        Set-Item -Path Function:ConvertFrom-CsvToJson -Value { param([string]$Path) Import-Csv -Path $Path | ConvertTo-Json -Depth 10 } -Force | Out-Null
        Set-Alias -Name csv-to-json -Value ConvertFrom-CsvToJson -ErrorAction SilentlyContinue
        # JSON to CSV
        Set-Item -Path Function:ConvertTo-CsvFromJson -Value { param([string]$Path) try { $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; if ($data -is [array]) { $data | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') } else { Write-Error "JSON must be an array of objects" } } catch { Write-Error "Failed to convert JSON to CSV: $_" } } -Force | Out-Null
        Set-Alias -Name json-to-csv -Value ConvertTo-CsvFromJson -ErrorAction SilentlyContinue

        # XML to JSON
        Set-Item -Path Function:ConvertFrom-XmlToJson -Value { param([string]$Path) try { $xml = [xml](Get-Content -LiteralPath $Path -Raw); $xml | ConvertTo-Json -Depth 100 } catch { Write-Error "Failed to parse XML: $_" } } -Force | Out-Null
        Set-Alias -Name xml-to-json -Value ConvertFrom-XmlToJson -ErrorAction SilentlyContinue

        # Markdown to HTML
        Set-Item -Path Function:ConvertTo-HtmlFromMarkdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.html' }; pandoc $InputPath -o $OutputPath } -Force | Out-Null
        Set-Alias -Name markdown-to-html -Value ConvertTo-HtmlFromMarkdown -ErrorAction SilentlyContinue
        # HTML to Markdown
        Set-Item -Path Function:ConvertFrom-HtmlToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.html$', '.md' }; pandoc -f html -t markdown $InputPath -o $OutputPath } -Force | Out-Null
        Set-Alias -Name html-to-markdown -Value ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue

        # Image convert
        Set-Item -Path Function:Convert-Image -Value { param([string]$InputPath, [string]$OutputPath) magick convert $InputPath $OutputPath } -Force | Out-Null
        Set-Alias -Name image-convert -Value Convert-Image -ErrorAction SilentlyContinue

        # Audio convert
        Set-Item -Path Function:Convert-Audio -Value { param([string]$InputPath, [string]$OutputPath) ffmpeg -i $InputPath $OutputPath } -Force | Out-Null
        Set-Alias -Name audio-convert -Value Convert-Audio -ErrorAction SilentlyContinue

        # PDF to text
        Set-Item -Path Function:ConvertFrom-PdfToText -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.pdf$', '.txt' }; pdftotext $InputPath $OutputPath } -Force | Out-Null
        Set-Alias -Name pdf-to-text -Value ConvertFrom-PdfToText -ErrorAction SilentlyContinue

        # Video to audio
        Set-Item -Path Function:ConvertFrom-VideoToAudio -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'mp3') }; ffmpeg -i $InputPath -vn -acodec libmp3lame $OutputPath } -Force | Out-Null
        Set-Alias -Name video-to-audio -Value ConvertFrom-VideoToAudio -ErrorAction SilentlyContinue

        # Video to GIF
        Set-Item -Path Function:ConvertFrom-VideoToGif -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'gif') }; ffmpeg -i $InputPath -vf "fps=10,scale=320:-1:flags=lanczos" $OutputPath } -Force | Out-Null
        Set-Alias -Name video-to-gif -Value ConvertFrom-VideoToGif -ErrorAction SilentlyContinue

        # Image resize
        Set-Item -Path Function:Resize-Image -Value { param([string]$InputPath, [string]$OutputPath, [int]$Width, [int]$Height) if (-not $OutputPath) { $OutputPath = $InputPath }; magick convert $InputPath -resize ${Width}x${Height} $OutputPath } -Force | Out-Null
        Set-Alias -Name image-resize -Value Resize-Image -ErrorAction SilentlyContinue

        # PDF merge
        Set-Item -Path Function:Merge-Pdf -Value { param([string[]]$InputPaths, [string]$OutputPath) pdftk $InputPaths cat output $OutputPath } -Force | Out-Null
        Set-Alias -Name pdf-merge -Value Merge-Pdf -ErrorAction SilentlyContinue

        # EPUB to Markdown
        Set-Item -Path Function:ConvertFrom-EpubToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.epub$', '.md' }; pandoc -f epub -t markdown $InputPath -o $OutputPath } -Force | Out-Null
        Set-Alias -Name epub-to-markdown -Value ConvertFrom-EpubToMarkdown -ErrorAction SilentlyContinue

        # DOCX to Markdown
        Set-Item -Path Function:ConvertFrom-DocxToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.docx$', '.md' }; pandoc -f docx -t markdown $InputPath -o $OutputPath } -Force | Out-Null
        Set-Alias -Name docx-to-markdown -Value ConvertFrom-DocxToMarkdown -ErrorAction SilentlyContinue

        # CSV to YAML
        Set-Item -Path Function:ConvertFrom-CsvToYaml -Value { param([string]$Path) Import-Csv -Path $Path | ConvertTo-Json -Depth 10 | yq eval -P | Out-File -FilePath ($Path -replace '\.csv$', '.yaml') -Encoding UTF8 } -Force | Out-Null
        Set-Alias -Name csv-to-yaml -Value ConvertFrom-CsvToYaml -ErrorAction SilentlyContinue

        # YAML to CSV
        Set-Item -Path Function:ConvertFrom-YamlToCsv -Value { param([string]$Path) yq eval -o=json $Path | ConvertFrom-Json | Export-Csv -NoTypeInformation -Path ($Path -replace '\.ya?ml$', '.csv') } -Force | Out-Null
        Set-Alias -Name yaml-to-csv -Value ConvertFrom-YamlToCsv -ErrorAction SilentlyContinue
    }
}

# Pretty-print JSON
<#
.SYNOPSIS
    Pretty-prints JSON data.
.DESCRIPTION
    Formats JSON data with proper indentation and structure.
#>
function Format-Json { if (-not (Test-Path Function:\Format-Json)) { Ensure-FileConversion }; return & (Get-Item Function:\Format-Json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name json-pretty -Value Format-Json -ErrorAction SilentlyContinue

# Convert YAML to JSON
<#
.SYNOPSIS
    Converts YAML to JSON format.
.DESCRIPTION
    Transforms YAML input to JSON output using yq.
#>
function ConvertFrom-Yaml { if (-not (Test-Path Function:\ConvertFrom-Yaml)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-Yaml -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name yaml-to-json -Value ConvertFrom-Yaml -ErrorAction SilentlyContinue

# Convert JSON to YAML
<#
.SYNOPSIS
    Converts JSON to YAML format.
.DESCRIPTION
    Transforms JSON input to YAML output using yq.
#>
function ConvertTo-Yaml { if (-not (Test-Path Function:\ConvertTo-Yaml)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertTo-Yaml -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name json-to-yaml -Value ConvertTo-Yaml -ErrorAction SilentlyContinue

# Encode to base64
<#
.SYNOPSIS
    Encodes input to base64 format.
.DESCRIPTION
    Converts file contents or string input to base64 encoded string.
.PARAMETER InputObject
    The file path or string to encode.
#>
function ConvertTo-Base64 { if (-not (Test-Path Function:\ConvertTo-Base64)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertTo-Base64 -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name to-base64 -Value ConvertTo-Base64 -ErrorAction SilentlyContinue

# Decode from base64
<#
.SYNOPSIS
    Decodes base64 input to text.
.DESCRIPTION
    Converts base64 encoded string back to readable text.
.PARAMETER InputObject
    The base64 string to decode.
#>
function ConvertFrom-Base64 { if (-not (Test-Path Function:\ConvertFrom-Base64)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-Base64 -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name from-base64 -Value ConvertFrom-Base64 -ErrorAction SilentlyContinue

# Convert CSV to JSON
<#
.SYNOPSIS
    Converts CSV file to JSON format.
.DESCRIPTION
    Reads a CSV file and outputs its contents as JSON.
.PARAMETER Path
    The path to the CSV file to convert.
#>
function ConvertFrom-CsvToJson { if (-not (Test-Path Function:\ConvertFrom-CsvToJson)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-CsvToJson -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name csv-to-json -Value ConvertFrom-CsvToJson -ErrorAction SilentlyContinue

# Convert JSON to CSV
<#
.SYNOPSIS
    Converts JSON file to CSV format.
.DESCRIPTION
    Parses a JSON file containing an array of objects and converts it to CSV.
.PARAMETER Path
    The path to the JSON file to convert.
#>
function ConvertTo-CsvFromJson { if (-not (Test-Path Function:\ConvertTo-CsvFromJson)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertTo-CsvFromJson -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name json-to-csv -Value ConvertTo-CsvFromJson -ErrorAction SilentlyContinue

# Convert XML to JSON
<#
.SYNOPSIS
    Converts XML file to JSON format.
.DESCRIPTION
    Parses an XML file and converts it to JSON representation.
.PARAMETER Path
    The path to the XML file to convert.
#>
function ConvertFrom-XmlToJson { if (-not (Test-Path Function:\ConvertFrom-XmlToJson)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-XmlToJson -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name xml-to-json -Value ConvertFrom-XmlToJson -ErrorAction SilentlyContinue

# Convert Markdown to HTML
<#
.SYNOPSIS
    Converts Markdown file to HTML.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to HTML format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromMarkdown { if (-not (Test-Path Function:\ConvertTo-HtmlFromMarkdown)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertTo-HtmlFromMarkdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name markdown-to-html -Value ConvertTo-HtmlFromMarkdown -ErrorAction SilentlyContinue

# Convert HTML to Markdown
<#
.SYNOPSIS
    Converts HTML file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an HTML file to Markdown format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-HtmlToMarkdown { if (-not (Test-Path Function:\ConvertFrom-HtmlToMarkdown)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name html-to-markdown -Value ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue

# Convert image formats
<#
.SYNOPSIS
    Converts image file formats.
.DESCRIPTION
    Uses ImageMagick to convert an image from one format to another.
.PARAMETER InputPath
    The path to the input image file.
.PARAMETER OutputPath
    The path for the output image file with desired format.
#>
function Convert-Image { if (-not (Test-Path Function:\Convert-Image)) { Ensure-FileConversion }; return & (Get-Item Function:\Convert-Image -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name image-convert -Value Convert-Image -ErrorAction SilentlyContinue

# Convert audio formats
<#
.SYNOPSIS
    Converts audio file formats.
.DESCRIPTION
    Uses ffmpeg to convert an audio file from one format to another.
.PARAMETER InputPath
    The path to the input audio file.
.PARAMETER OutputPath
    The path for the output audio file with desired format.
#>
function Convert-Audio { if (-not (Test-Path Function:\Convert-Audio)) { Ensure-FileConversion }; return & (Get-Item Function:\Convert-Audio -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name audio-convert -Value Convert-Audio -ErrorAction SilentlyContinue

# Convert PDF to text
<#
.SYNOPSIS
    Extracts text from PDF file.
.DESCRIPTION
    Uses pdftotext to extract plain text from a PDF file.
.PARAMETER InputPath
    The path to the PDF file.
.PARAMETER OutputPath
    The path for the output text file. If not specified, uses input path with .txt extension.
#>
function ConvertFrom-PdfToText { if (-not (Test-Path Function:\ConvertFrom-PdfToText)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-PdfToText -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name pdf-to-text -Value ConvertFrom-PdfToText -ErrorAction SilentlyContinue

# Extract audio from video
<#
.SYNOPSIS
    Extracts audio from video file.
.DESCRIPTION
    Uses ffmpeg to extract audio track from a video file as MP3.
.PARAMETER InputPath
    The path to the video file.
.PARAMETER OutputPath
    The path for the output audio file. If not specified, uses input path with .mp3 extension.
#>
function ConvertFrom-VideoToAudio { if (-not (Test-Path Function:\ConvertFrom-VideoToAudio)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-VideoToAudio -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name video-to-audio -Value ConvertFrom-VideoToAudio -ErrorAction SilentlyContinue

# Convert video to GIF
<#
.SYNOPSIS
    Converts video to GIF.
.DESCRIPTION
    Uses ffmpeg to convert a video file to animated GIF.
.PARAMETER InputPath
    The path to the video file.
.PARAMETER OutputPath
    The path for the output GIF file. If not specified, uses input path with .gif extension.
#>
function ConvertFrom-VideoToGif { if (-not (Test-Path Function:\ConvertFrom-VideoToGif)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-VideoToGif -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name video-to-gif -Value ConvertFrom-VideoToGif -ErrorAction SilentlyContinue

# Resize image
<#
.SYNOPSIS
    Resizes an image.
.DESCRIPTION
    Uses ImageMagick to resize an image to specified dimensions.
.PARAMETER InputPath
    The path to the input image file.
.PARAMETER OutputPath
    The path for the output image file.
.PARAMETER Width
    The desired width.
.PARAMETER Height
    The desired height.
#>
function Resize-Image { if (-not (Test-Path Function:\Resize-Image)) { Ensure-FileConversion }; return & (Get-Item Function:\Resize-Image -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name image-resize -Value Resize-Image -ErrorAction SilentlyContinue

# Merge PDF files
<#
.SYNOPSIS
    Merges multiple PDF files.
.DESCRIPTION
    Uses pdftk to combine multiple PDF files into one.
.PARAMETER InputPaths
    Array of paths to PDF files to merge.
.PARAMETER OutputPath
    The path for the output merged PDF file.
#>
function Merge-Pdf { if (-not (Test-Path Function:\Merge-Pdf)) { Ensure-FileConversion }; return & (Get-Item Function:\Merge-Pdf -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name pdf-merge -Value Merge-Pdf -ErrorAction SilentlyContinue

# Convert EPUB to Markdown
<#
.SYNOPSIS
    Converts EPUB file to Markdown.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to Markdown format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-EpubToMarkdown { if (-not (Test-Path Function:\ConvertFrom-EpubToMarkdown)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-EpubToMarkdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name epub-to-markdown -Value ConvertFrom-EpubToMarkdown -ErrorAction SilentlyContinue

# Convert DOCX to Markdown
<#
.SYNOPSIS
    Converts DOCX file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a DOCX file to Markdown format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-DocxToMarkdown { if (-not (Test-Path Function:\ConvertFrom-DocxToMarkdown)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-DocxToMarkdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name docx-to-markdown -Value ConvertFrom-DocxToMarkdown -ErrorAction SilentlyContinue

# Convert CSV to YAML
<#
.SYNOPSIS
    Converts CSV file to YAML format.
.DESCRIPTION
    Reads a CSV file and outputs its contents as YAML.
.PARAMETER Path
    The path to the CSV file to convert.
#>
function ConvertFrom-CsvToYaml { if (-not (Test-Path Function:\ConvertFrom-CsvToYaml)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-CsvToYaml -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name csv-to-yaml -Value ConvertFrom-CsvToYaml -ErrorAction SilentlyContinue

# Convert YAML to CSV
<#
.SYNOPSIS
    Converts YAML file to CSV format.
.DESCRIPTION
    Reads a YAML file and outputs its contents as CSV.
.PARAMETER Path
    The path to the YAML file to convert.
#>
function ConvertFrom-YamlToCsv { if (-not (Test-Path Function:\ConvertFrom-YamlToCsv)) { Ensure-FileConversion }; return & (Get-Item Function:\ConvertFrom-YamlToCsv -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
Set-Alias -Name yaml-to-csv -Value ConvertFrom-YamlToCsv -ErrorAction SilentlyContinue
