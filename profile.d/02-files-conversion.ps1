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
        Set-Item -Path Function:json-pretty -Value {
            param(
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,
                [Parameter(ValueFromRemainingArguments = $true)]
                $fileArgs
            )
            process {
                if ($fileArgs) {
                    Get-Content -Raw -LiteralPath @fileArgs | ConvertFrom-Json | ConvertTo-Json -Depth 10
                }
                elseif ($InputObject) {
                    $InputObject | ConvertFrom-Json | ConvertTo-Json -Depth 10
                }
                else {
                    $input | ConvertFrom-Json | ConvertTo-Json -Depth 10
                }
            }
        } -Force | Out-Null

        # YAML to JSON
        Set-Item -Path Function:yaml-to-json -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) yq eval -o=json @fileArgs } -Force | Out-Null
        # JSON to YAML
        Set-Item -Path Function:json-to-yaml -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) yq eval -P @fileArgs } -Force | Out-Null

        # Base64 encode
        Set-Item -Path Function:to-base64 -Value { param([Parameter(ValueFromPipeline = $true)] $InputObject) process { if ($InputObject -is [string] -and (Test-Path -LiteralPath $InputObject)) { [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $InputObject))) } else { $bytes = [Text.Encoding]::UTF8.GetBytes($InputObject); [Convert]::ToBase64String($bytes) } } } -Force | Out-Null
        # Base64 decode
        Set-Item -Path Function:from-base64 -Value { param([Parameter(ValueFromPipeline = $true)] $InputObject) process { $s = ($InputObject -join "") -replace '\s+', ''; try { $bytes = [Convert]::FromBase64String($s); [Text.Encoding]::UTF8.GetString($bytes) } catch { Write-Error "Invalid base64 input" } } } -Force | Out-Null

        # CSV to JSON
        Set-Item -Path Function:csv-to-json -Value { param([string]$Path) Import-Csv -Path $Path | ConvertTo-Json -Depth 10 } -Force | Out-Null
        # JSON to CSV
        Set-Item -Path Function:json-to-csv -Value { param([string]$Path) try { $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; if ($data -is [array]) { $data | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') } else { Write-Error "JSON must be an array of objects" } } catch { Write-Error "Failed to convert JSON to CSV: $_" } } -Force | Out-Null

        # XML to JSON
        Set-Item -Path Function:xml-to-json -Value { param([string]$Path) try { $xml = [xml](Get-Content -LiteralPath $Path -Raw); $xml | ConvertTo-Json -Depth 100 } catch { Write-Error "Failed to parse XML: $_" } } -Force | Out-Null

        # Markdown to HTML
        Set-Item -Path Function:markdown-to-html -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.html' }; pandoc $InputPath -o $OutputPath } -Force | Out-Null
        # HTML to Markdown
        Set-Item -Path Function:html-to-markdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.html$', '.md' }; pandoc -f html -t markdown $InputPath -o $OutputPath } -Force | Out-Null

        # Image convert
        Set-Item -Path Function:image-convert -Value { param([string]$InputPath, [string]$OutputPath) magick convert $InputPath $OutputPath } -Force | Out-Null

        # Audio convert
        Set-Item -Path Function:audio-convert -Value { param([string]$InputPath, [string]$OutputPath) ffmpeg -i $InputPath $OutputPath } -Force | Out-Null

        # PDF to text
        Set-Item -Path Function:pdf-to-text -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.pdf$', '.txt' }; pdftotext $InputPath $OutputPath } -Force | Out-Null

        # Video to audio
        Set-Item -Path Function:video-to-audio -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'mp3') }; ffmpeg -i $InputPath -vn -acodec libmp3lame $OutputPath } -Force | Out-Null

        # Video to GIF
        Set-Item -Path Function:video-to-gif -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'gif') }; ffmpeg -i $InputPath -vf "fps=10,scale=320:-1:flags=lanczos" $OutputPath } -Force | Out-Null

        # Image resize
        Set-Item -Path Function:image-resize -Value { param([string]$InputPath, [string]$OutputPath, [int]$Width, [int]$Height) if (-not $OutputPath) { $OutputPath = $InputPath }; magick convert $InputPath -resize ${Width}x${Height} $OutputPath } -Force | Out-Null

        # PDF merge
        Set-Item -Path Function:pdf-merge -Value { param([string[]]$InputPaths, [string]$OutputPath) pdftk $InputPaths cat output $OutputPath } -Force | Out-Null

        # EPUB to Markdown
        Set-Item -Path Function:epub-to-markdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.epub$', '.md' }; pandoc -f epub -t markdown $InputPath -o $OutputPath } -Force | Out-Null

        # DOCX to Markdown
        Set-Item -Path Function:docx-to-markdown -Value { param([string]$InputPath, [string]$OutputPath) if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.docx$', '.md' }; pandoc -f docx -t markdown $InputPath -o $OutputPath } -Force | Out-Null

        # CSV to YAML
        Set-Item -Path Function:csv-to-yaml -Value { param([string]$Path) Import-Csv -Path $Path | ConvertTo-Json -Depth 10 | yq eval -P | Out-File -FilePath ($Path -replace '\.csv$', '.yaml') -Encoding UTF8 } -Force | Out-Null

        # YAML to CSV
        Set-Item -Path Function:yaml-to-csv -Value { param([string]$Path) yq eval -o=json $Path | ConvertFrom-Json | Export-Csv -NoTypeInformation -Path ($Path -replace '\.ya?ml$', '.csv') } -Force | Out-Null
    }
}

# Pretty-print JSON
<#
.SYNOPSIS
    Pretty-prints JSON data.
.DESCRIPTION
    Formats JSON data with proper indentation and structure.
#>
function json-pretty { if (-not (Test-Path Function:\json-pretty)) { Ensure-FileConversion }; return & (Get-Item Function:\json-pretty -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert YAML to JSON
<#
.SYNOPSIS
    Converts YAML to JSON format.
.DESCRIPTION
    Transforms YAML input to JSON output using yq.
#>
function yaml-to-json { if (-not (Test-Path Function:\yaml-to-json)) { Ensure-FileConversion }; return & (Get-Item Function:\yaml-to-json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert JSON to YAML
<#
.SYNOPSIS
    Converts JSON to YAML format.
.DESCRIPTION
    Transforms JSON input to YAML output using yq.
#>
function json-to-yaml { if (-not (Test-Path Function:\json-to-yaml)) { Ensure-FileConversion }; return & (Get-Item Function:\json-to-yaml -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Encode to base64
<#
.SYNOPSIS
    Encodes input to base64 format.
.DESCRIPTION
    Converts file contents or string input to base64 encoded string.
.PARAMETER InputObject
    The file path or string to encode.
#>
function to-base64 { if (-not (Test-Path Function:\to-base64)) { Ensure-FileConversion }; return & (Get-Item Function:\to-base64 -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Decode from base64
<#
.SYNOPSIS
    Decodes base64 input to text.
.DESCRIPTION
    Converts base64 encoded string back to readable text.
.PARAMETER InputObject
    The base64 string to decode.
#>
function from-base64 { if (-not (Test-Path Function:\from-base64)) { Ensure-FileConversion }; return & (Get-Item Function:\from-base64 -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert CSV to JSON
<#
.SYNOPSIS
    Converts CSV file to JSON format.
.DESCRIPTION
    Reads a CSV file and outputs its contents as JSON.
.PARAMETER Path
    The path to the CSV file to convert.
#>
function csv-to-json { if (-not (Test-Path Function:\csv-to-json)) { Ensure-FileConversion }; return & (Get-Item Function:\csv-to-json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert JSON to CSV
<#
.SYNOPSIS
    Converts JSON file to CSV format.
.DESCRIPTION
    Parses a JSON file containing an array of objects and converts it to CSV.
.PARAMETER Path
    The path to the JSON file to convert.
#>
function json-to-csv { if (-not (Test-Path Function:\json-to-csv)) { Ensure-FileConversion }; return & (Get-Item Function:\json-to-csv -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert XML to JSON
<#
.SYNOPSIS
    Converts XML file to JSON format.
.DESCRIPTION
    Parses an XML file and converts it to JSON representation.
.PARAMETER Path
    The path to the XML file to convert.
#>
function xml-to-json { if (-not (Test-Path Function:\xml-to-json)) { Ensure-FileConversion }; return & (Get-Item Function:\xml-to-json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function markdown-to-html { if (-not (Test-Path Function:\markdown-to-html)) { Ensure-FileConversion }; return & (Get-Item Function:\markdown-to-html -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function html-to-markdown { if (-not (Test-Path Function:\html-to-markdown)) { Ensure-FileConversion }; return & (Get-Item Function:\html-to-markdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function image-convert { if (-not (Test-Path Function:\image-convert)) { Ensure-FileConversion }; return & (Get-Item Function:\image-convert -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function audio-convert { if (-not (Test-Path Function:\audio-convert)) { Ensure-FileConversion }; return & (Get-Item Function:\audio-convert -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function pdf-to-text { if (-not (Test-Path Function:\pdf-to-text)) { Ensure-FileConversion }; return & (Get-Item Function:\pdf-to-text -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function video-to-audio { if (-not (Test-Path Function:\video-to-audio)) { Ensure-FileConversion }; return & (Get-Item Function:\video-to-audio -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function video-to-gif { if (-not (Test-Path Function:\video-to-gif)) { Ensure-FileConversion }; return & (Get-Item Function:\video-to-gif -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function image-resize { if (-not (Test-Path Function:\image-resize)) { Ensure-FileConversion }; return & (Get-Item Function:\image-resize -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function pdf-merge { if (-not (Test-Path Function:\pdf-merge)) { Ensure-FileConversion }; return & (Get-Item Function:\pdf-merge -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function epub-to-markdown { if (-not (Test-Path Function:\epub-to-markdown)) { Ensure-FileConversion }; return & (Get-Item Function:\epub-to-markdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

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
function docx-to-markdown { if (-not (Test-Path Function:\docx-to-markdown)) { Ensure-FileConversion }; return & (Get-Item Function:\docx-to-markdown -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert CSV to YAML
<#
.SYNOPSIS
    Converts CSV file to YAML format.
.DESCRIPTION
    Reads a CSV file and outputs its contents as YAML.
.PARAMETER Path
    The path to the CSV file to convert.
#>
function csv-to-yaml { if (-not (Test-Path Function:\csv-to-yaml)) { Ensure-FileConversion }; return & (Get-Item Function:\csv-to-yaml -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Convert YAML to CSV
<#
.SYNOPSIS
    Converts YAML file to CSV format.
.DESCRIPTION
    Reads a YAML file and outputs its contents as CSV.
.PARAMETER Path
    The path to the YAML file to convert.
#>
function yaml-to-csv { if (-not (Test-Path Function:\yaml-to-csv)) { Ensure-FileConversion }; return & (Get-Item Function:\yaml-to-csv -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
