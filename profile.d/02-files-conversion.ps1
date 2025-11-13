# ===============================================
# 02-files-conversion.ps1
# File conversion utilities
# ===============================================

# XML to JSON helper function
<#
.SYNOPSIS
    Converts an XML element to a JSON-compatible PowerShell object.
.DESCRIPTION
    Recursively converts an XML element and its children to a PowerShell object
    that can be easily serialized to JSON. Handles arrays for repeated elements
    and preserves text content.
.PARAMETER Element
    The XML element to convert to a JSON object.
.OUTPUTS
    PSCustomObject representing the XML structure in JSON-compatible format.
#>
function Convert-XmlToJsonObject {
    param([System.Xml.XmlElement]$Element)

    $obj = [ordered]@{}
    $hasElements = $false

    foreach ($child in $Element.ChildNodes) {
        if ($child.NodeType -eq 'Element') {
            $hasElements = $true
            $childName = $child.LocalName
            $childValue = Convert-XmlToJsonObject $child

            if ($obj.Contains($childName)) {
                if ($obj[$childName] -isnot [array]) {
                    $obj[$childName] = @($obj[$childName])
                }
                $obj[$childName] += $childValue
            }
            else {
                $obj[$childName] = $childValue
            }
        }
        elseif ($child.NodeType -eq 'Text' -and -not [string]::IsNullOrWhiteSpace($child.Value)) {
            $obj['#text'] = $child.Value
        }
    }

    if ($hasElements) {
        return [PSCustomObject]$obj
    }
    else {
        return $obj['#text']
    }
}

# Lazy bulk initializer for file conversion helpers
<#
.SYNOPSIS
    Initializes file conversion utility functions on first use.
.DESCRIPTION
    Sets up all file conversion utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
function Ensure-FileConversion {
    if ($global:FileConversionInitialized) { return }

    # JSON pretty-print
    Set-Item -Path Function:Global:_Format-Json -Value {
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
                # Only show warning when not running in Pester tests
                if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {
                    Write-Warning "Failed to pretty-print JSON: $($_.Exception.Message)"
                }
                if ($null -ne $rawInput) {
                    Write-Output $rawInput
                }
            }
        }
    } -Force

    # YAML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-Yaml -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) try { $resolvedPath = Resolve-Path @fileArgs | Select-Object -ExpandProperty Path; $result = & yq eval -o=json '.' $resolvedPath 2>$null; if ($LASTEXITCODE -ne 0) { throw "yq command failed" }; $result } catch { Write-Error "Failed to convert YAML to JSON: $_" } } -Force

    # JSON to YAML
    Set-Item -Path Function:Global:_ConvertTo-Yaml -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) try { $resolvedPath = Resolve-Path @fileArgs | Select-Object -ExpandProperty Path; $output = & yq eval -p json -o yaml '.' $resolvedPath 2>$null; if ($LASTEXITCODE -ne 0) { throw "yq command failed" }; $output -join "`n" } catch { Write-Error "Failed to convert JSON to YAML: $_" } } -Force

    # Base64 encode
    Set-Item -Path Function:Global:_ConvertTo-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            if ($InputObject -is [byte[]]) {
                return [Convert]::ToBase64String($InputObject)
            }
            $text = [string]$InputObject
            $bytes = [Text.Encoding]::UTF8.GetBytes($text)
            return [Convert]::ToBase64String($bytes)
        }
    } -Force

    # Base64 decode
    Set-Item -Path Function:Global:_ConvertFrom-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            $s = [string]$InputObject -replace '\s+', ''
            try {
                $bytes = [Convert]::FromBase64String($s)
                return [Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                Write-Error "Invalid base64 input: $_"
            }
        }
    } -Force

    # CSV to JSON
    Set-Item -Path Function:Global:_ConvertFrom-CsvToJson -Value { param([string]$Path) try { Import-Csv -Path $Path | ConvertTo-Json -Depth 10 } catch { Write-Error "Failed to convert CSV to JSON: $_" } } -Force

    # JSON to CSV
    Set-Item -Path Function:Global:_ConvertTo-CsvFromJson -Value { param([string]$Path) try { $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; if ($data -is [array]) { $data | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') } elseif ($data -is [PSCustomObject]) { @($data) | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') } else { Write-Error "JSON must be an array of objects or a single object" } } catch { Write-Error "Failed to convert JSON to CSV: $_" } } -Force

    # XML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-XmlToJson -Value { param([string]$Path) try { $xml = [xml](Get-Content -LiteralPath $Path -Raw); $result = @{}; $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement; [PSCustomObject]$result | ConvertTo-Json -Depth 100 } catch { Write-Error "Failed to parse XML: $_" } } -Force

    # Markdown to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.html' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert Markdown to HTML: $_" } } -Force

    # HTML to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-HtmlToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.html$', '.md' }; pandoc -f html -t markdown $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert HTML to Markdown: $_" } } -Force

    # Image convert
    Set-Item -Path Function:Global:_Convert-Image -Value { param([string]$InputPath, [string]$OutputPath) try { magick $InputPath $OutputPath 2>$null } catch { Write-Error "Failed to convert image: $_" } } -Force

    # Audio convert
    Set-Item -Path Function:Global:_Convert-Audio -Value { param([string]$InputPath, [string]$OutputPath) try { ffmpeg -i $InputPath $OutputPath 2>$null } catch { Write-Error "Failed to convert audio: $_" } } -Force

    # PDF to text
    Set-Item -Path Function:Global:_ConvertFrom-PdfToText -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.pdf$', '.txt' }; pdftotext $InputPath $OutputPath 2>$null } catch { Write-Error "Failed to convert PDF to text: $_" } } -Force

    # Video to audio
    Set-Item -Path Function:Global:_ConvertFrom-VideoToAudio -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'mp3') }; ffmpeg -i $InputPath -vn -acodec libmp3lame $OutputPath 2>$null } catch { Write-Error "Failed to extract audio from video: $_" } } -Force

    # Video to GIF
    Set-Item -Path Function:Global:_ConvertFrom-VideoToGif -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'gif') }; ffmpeg -i $InputPath -vf "fps=10,scale=320:-1:flags=lanczos" $OutputPath 2>$null } catch { Write-Error "Failed to convert video to GIF: $_" } } -Force

    # Image resize
    Set-Item -Path Function:Global:_Resize-Image -Value { param([string]$InputPath, [string]$OutputPath, [int]$Width, [int]$Height) try { if (-not $OutputPath) { $OutputPath = $InputPath }; magick $InputPath -resize ${Width}x${Height} $OutputPath 2>$null } catch { Write-Error "Failed to resize image: $_" } } -Force

    # PDF merge
    Set-Item -Path Function:Global:_Merge-Pdf -Value { param([string[]]$InputPaths, [string]$OutputPath) try { pdftk $InputPaths cat output $OutputPath 2>$null } catch { Write-Error "Failed to merge PDF files: $_" } } -Force

    # EPUB to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-EpubToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.epub$', '.md' }; pandoc -f epub -t markdown $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert EPUB to Markdown: $_" } } -Force

    # DOCX to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-DocxToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.docx$', '.md' }; pandoc -f docx -t markdown $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert DOCX to Markdown: $_" } } -Force

    # CSV to YAML
    Set-Item -Path Function:Global:_ConvertFrom-CsvToYaml -Value { param([string]$Path) try { Import-Csv -Path $Path | ConvertTo-Json -Depth 10 | & yq eval -P | Out-File -FilePath ($Path -replace '\.csv$', '.yaml') -Encoding UTF8 } catch { Write-Error "Failed to convert CSV to YAML: $_" } } -Force

    # YAML to CSV
    Set-Item -Path Function:Global:_ConvertFrom-YamlToCsv -Value { param([string]$Path) try { $json = & yq eval -o=json $Path 2>$null; if ($LASTEXITCODE -eq 0 -and $json -and $json -ne 'null') { $data = $json | ConvertFrom-Json; if ($data) { $data | Export-Csv -NoTypeInformation -Path ($Path -replace '\.ya?ml$', '.csv') } } } catch { Write-Error "Failed to convert YAML to CSV: $_" } } -Force

    # Markdown to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.pdf' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert Markdown to PDF: $_" } } -Force

    # Markdown to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.docx' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert Markdown to DOCX: $_" } } -Force

    # Markdown to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.tex' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert Markdown to LaTeX: $_" } } -Force

    # HTML to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromHtml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.html?$', '.pdf' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert HTML to PDF: $_" } } -Force

    # DOCX to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromDocx -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.docx$', '.html' }; pandoc -f docx -t html $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert DOCX to HTML: $_" } } -Force

    # DOCX to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromDocx -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.docx$', '.pdf' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert DOCX to PDF: $_" } } -Force

    # EPUB to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromEpub -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.epub$', '.html' }; pandoc -f epub -t html $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert EPUB to HTML: $_" } } -Force

    # EPUB to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromEpub -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.epub$', '.pdf' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert EPUB to PDF: $_" } } -Force

    # LaTeX to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-LaTeXToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.tex$', '.md' }; pandoc -f latex -t markdown $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert LaTeX to Markdown: $_" } } -Force

    # RST to Markdown
    Set-Item -Path Function:Global:_ConvertFrom-RstToMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.rst$', '.md' }; pandoc -f rst -t markdown $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert RST to Markdown: $_" } } -Force

    # RST to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromRst -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.rst$', '.html' }; pandoc -f rst -t html $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert RST to HTML: $_" } } -Force

    # RST to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromRst -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.rst$', '.pdf' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert RST to PDF: $_" } } -Force

    # RST to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromRst -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.rst$', '.docx' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert RST to DOCX: $_" } } -Force

    # RST to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromRst -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.rst$', '.tex' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert RST to LaTeX: $_" } } -Force

    # LaTeX to HTML
    Set-Item -Path Function:Global:_ConvertTo-HtmlFromLaTeX -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.tex$', '.html' }; pandoc -f latex -t html $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert LaTeX to HTML: $_" } } -Force

    # LaTeX to PDF
    Set-Item -Path Function:Global:_ConvertTo-PdfFromLaTeX -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.tex$', '.pdf' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert LaTeX to PDF: $_" } } -Force

    # LaTeX to DOCX
    Set-Item -Path Function:Global:_ConvertTo-DocxFromLaTeX -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.tex$', '.docx' }; pandoc $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert LaTeX to DOCX: $_" } } -Force

    # LaTeX to RST
    Set-Item -Path Function:Global:_ConvertTo-RstFromLaTeX -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.tex$', '.rst' }; pandoc -f latex -t rst $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert LaTeX to RST: $_" } } -Force

    # Markdown to RST
    Set-Item -Path Function:Global:_ConvertTo-RstFromMarkdown -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.md$', '.rst' }; pandoc -f markdown -t rst $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert Markdown to RST: $_" } } -Force

    # HTML to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromHtml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.html?$', '.tex' }; pandoc -f html -t latex $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert HTML to LaTeX: $_" } } -Force

    # DOCX to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromDocx -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.docx$', '.tex' }; pandoc -f docx -t latex $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert DOCX to LaTeX: $_" } } -Force

    # EPUB to LaTeX
    Set-Item -Path Function:Global:_ConvertTo-LaTeXFromEpub -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.epub$', '.tex' }; pandoc -f epub -t latex $InputPath -o $OutputPath 2>$null } catch { Write-Error "Failed to convert EPUB to LaTeX: $_" } } -Force

    # Mark as initialized
    $global:FileConversionInitialized = $true
}

# Pretty-print JSON
<#
.SYNOPSIS
    Pretty-prints JSON data.
.DESCRIPTION
    Formats JSON data with proper indentation and structure.
#>
function Format-Json {
    param([Parameter(ValueFromPipeline = $true)] $InputObject, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _Format-Json @PSBoundParameters
}
Set-Alias -Name json-pretty -Value Format-Json -ErrorAction SilentlyContinue

# Convert YAML to JSON
<#
.SYNOPSIS
    Converts YAML to JSON format.
.DESCRIPTION
    Transforms YAML input to JSON output using yq.
#>
function ConvertFrom-Yaml {
    param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-Yaml @PSBoundParameters
}
Set-Alias -Name yaml-to-json -Value ConvertFrom-Yaml -ErrorAction SilentlyContinue

# Convert JSON to YAML
<#
.SYNOPSIS
    Converts JSON to YAML format.
.DESCRIPTION
    Transforms JSON input to YAML output using yq.
#>
function ConvertTo-Yaml {
    param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-Yaml @PSBoundParameters
}
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
function ConvertTo-Base64 {
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-Base64 @PSBoundParameters
}
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
function ConvertFrom-Base64 {
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-Base64 @PSBoundParameters
}
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
function ConvertFrom-CsvToJson {
    param([string]$Path)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-CsvToJson @PSBoundParameters
}
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
function ConvertTo-CsvFromJson {
    param([string]$Path)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-CsvFromJson @PSBoundParameters
}
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
function ConvertFrom-XmlToJson {
    param([string]$Path)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-XmlToJson @PSBoundParameters
}
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
function ConvertTo-HtmlFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-HtmlFromMarkdown @PSBoundParameters
}
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
function ConvertFrom-HtmlToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-HtmlToMarkdown @PSBoundParameters
}
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
function Convert-Image {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _Convert-Image @PSBoundParameters
}
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
function Convert-Audio {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _Convert-Audio @PSBoundParameters
}
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
function ConvertFrom-PdfToText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-PdfToText @PSBoundParameters
}
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
function ConvertFrom-VideoToAudio {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-VideoToAudio @PSBoundParameters
}
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
function ConvertFrom-VideoToGif {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-VideoToGif @PSBoundParameters
}
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
function Resize-Image {
    param([string]$InputPath, [string]$OutputPath, [int]$Width, [int]$Height)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _Resize-Image @PSBoundParameters
}
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
function Merge-Pdf {
    param([string[]]$InputPaths, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _Merge-Pdf @PSBoundParameters
}
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
function ConvertFrom-EpubToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-EpubToMarkdown @PSBoundParameters
}
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
function ConvertFrom-DocxToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-DocxToMarkdown @PSBoundParameters
}
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
function ConvertFrom-CsvToYaml {
    param([string]$Path)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-CsvToYaml @PSBoundParameters
}
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
function ConvertFrom-YamlToCsv {
    param([string]$Path)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-YamlToCsv @PSBoundParameters
}
Set-Alias -Name yaml-to-csv -Value ConvertFrom-YamlToCsv -ErrorAction SilentlyContinue

# Convert Markdown to PDF
<#
.SYNOPSIS
    Converts Markdown file to PDF.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to PDF format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-PdfFromMarkdown @PSBoundParameters
}
Set-Alias -Name markdown-to-pdf -Value ConvertTo-PdfFromMarkdown -ErrorAction SilentlyContinue

# Convert Markdown to DOCX
<#
.SYNOPSIS
    Converts Markdown file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
#>
function ConvertTo-DocxFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-DocxFromMarkdown @PSBoundParameters
}
Set-Alias -Name markdown-to-docx -Value ConvertTo-DocxFromMarkdown -ErrorAction SilentlyContinue

# Convert Markdown to LaTeX
<#
.SYNOPSIS
    Converts Markdown file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to LaTeX format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-LaTeXFromMarkdown @PSBoundParameters
}
Set-Alias -Name markdown-to-latex -Value ConvertTo-LaTeXFromMarkdown -ErrorAction SilentlyContinue

# Convert HTML to PDF
<#
.SYNOPSIS
    Converts HTML file to PDF.
.DESCRIPTION
    Uses pandoc to convert an HTML file to PDF format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-PdfFromHtml @PSBoundParameters
}
Set-Alias -Name html-to-pdf -Value ConvertTo-PdfFromHtml -ErrorAction SilentlyContinue

# Convert DOCX to HTML
<#
.SYNOPSIS
    Converts DOCX file to HTML.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to HTML format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-HtmlFromDocx @PSBoundParameters
}
Set-Alias -Name docx-to-html -Value ConvertTo-HtmlFromDocx -ErrorAction SilentlyContinue

# Convert DOCX to PDF
<#
.SYNOPSIS
    Converts DOCX file to PDF.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to PDF format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-PdfFromDocx @PSBoundParameters
}
Set-Alias -Name docx-to-pdf -Value ConvertTo-PdfFromDocx -ErrorAction SilentlyContinue

# Convert EPUB to HTML
<#
.SYNOPSIS
    Converts EPUB file to HTML.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to HTML format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-HtmlFromEpub @PSBoundParameters
}
Set-Alias -Name epub-to-html -Value ConvertTo-HtmlFromEpub -ErrorAction SilentlyContinue

# Convert EPUB to PDF
<#
.SYNOPSIS
    Converts EPUB file to PDF.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to PDF format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-PdfFromEpub @PSBoundParameters
}
Set-Alias -Name epub-to-pdf -Value ConvertTo-PdfFromEpub -ErrorAction SilentlyContinue

# Convert LaTeX to Markdown
<#
.SYNOPSIS
    Converts LaTeX file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to Markdown format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-LaTeXToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-LaTeXToMarkdown @PSBoundParameters
}
Set-Alias -Name latex-to-markdown -Value ConvertFrom-LaTeXToMarkdown -ErrorAction SilentlyContinue

# Convert RST to Markdown
<#
.SYNOPSIS
    Converts RST file to Markdown.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to Markdown format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output Markdown file. If not specified, uses input path with .md extension.
#>
function ConvertFrom-RstToMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertFrom-RstToMarkdown @PSBoundParameters
}
Set-Alias -Name rst-to-markdown -Value ConvertFrom-RstToMarkdown -ErrorAction SilentlyContinue

# Convert RST to HTML
<#
.SYNOPSIS
    Converts RST file to HTML.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to HTML format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-HtmlFromRst @PSBoundParameters
}
Set-Alias -Name rst-to-html -Value ConvertTo-HtmlFromRst -ErrorAction SilentlyContinue

# Convert RST to PDF
<#
.SYNOPSIS
    Converts RST file to PDF.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to PDF format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-PdfFromRst @PSBoundParameters
}
Set-Alias -Name rst-to-pdf -Value ConvertTo-PdfFromRst -ErrorAction SilentlyContinue

# Convert RST to DOCX
<#
.SYNOPSIS
    Converts RST file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
#>
function ConvertTo-DocxFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-DocxFromRst @PSBoundParameters
}
Set-Alias -Name rst-to-docx -Value ConvertTo-DocxFromRst -ErrorAction SilentlyContinue

# Convert RST to LaTeX
<#
.SYNOPSIS
    Converts RST file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a reStructuredText (RST) file to LaTeX format.
.PARAMETER InputPath
    The path to the RST file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromRst {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-LaTeXFromRst @PSBoundParameters
}
Set-Alias -Name rst-to-latex -Value ConvertTo-LaTeXFromRst -ErrorAction SilentlyContinue

# Convert LaTeX to HTML
<#
.SYNOPSIS
    Converts LaTeX file to HTML.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to HTML format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output HTML file. If not specified, uses input path with .html extension.
#>
function ConvertTo-HtmlFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-HtmlFromLaTeX @PSBoundParameters
}
Set-Alias -Name latex-to-html -Value ConvertTo-HtmlFromLaTeX -ErrorAction SilentlyContinue

# Convert LaTeX to PDF
<#
.SYNOPSIS
    Converts LaTeX file to PDF.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to PDF format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output PDF file. If not specified, uses input path with .pdf extension.
#>
function ConvertTo-PdfFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-PdfFromLaTeX @PSBoundParameters
}
Set-Alias -Name latex-to-pdf -Value ConvertTo-PdfFromLaTeX -ErrorAction SilentlyContinue

# Convert LaTeX to DOCX
<#
.SYNOPSIS
    Converts LaTeX file to DOCX.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to Microsoft Word DOCX format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output DOCX file. If not specified, uses input path with .docx extension.
#>
function ConvertTo-DocxFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-DocxFromLaTeX @PSBoundParameters
}
Set-Alias -Name latex-to-docx -Value ConvertTo-DocxFromLaTeX -ErrorAction SilentlyContinue

# Convert LaTeX to RST
<#
.SYNOPSIS
    Converts LaTeX file to RST.
.DESCRIPTION
    Uses pandoc to convert a LaTeX file to reStructuredText (RST) format.
.PARAMETER InputPath
    The path to the LaTeX file.
.PARAMETER OutputPath
    The path for the output RST file. If not specified, uses input path with .rst extension.
#>
function ConvertTo-RstFromLaTeX {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-RstFromLaTeX @PSBoundParameters
}
Set-Alias -Name latex-to-rst -Value ConvertTo-RstFromLaTeX -ErrorAction SilentlyContinue

# Convert Markdown to RST
<#
.SYNOPSIS
    Converts Markdown file to RST.
.DESCRIPTION
    Uses pandoc to convert a Markdown file to reStructuredText (RST) format.
.PARAMETER InputPath
    The path to the Markdown file.
.PARAMETER OutputPath
    The path for the output RST file. If not specified, uses input path with .rst extension.
#>
function ConvertTo-RstFromMarkdown {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-RstFromMarkdown @PSBoundParameters
}
Set-Alias -Name markdown-to-rst -Value ConvertTo-RstFromMarkdown -ErrorAction SilentlyContinue

# Convert HTML to LaTeX
<#
.SYNOPSIS
    Converts HTML file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an HTML file to LaTeX format.
.PARAMETER InputPath
    The path to the HTML file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-LaTeXFromHtml @PSBoundParameters
}
Set-Alias -Name html-to-latex -Value ConvertTo-LaTeXFromHtml -ErrorAction SilentlyContinue

# Convert DOCX to LaTeX
<#
.SYNOPSIS
    Converts DOCX file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert a Microsoft Word DOCX file to LaTeX format.
.PARAMETER InputPath
    The path to the DOCX file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromDocx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-LaTeXFromDocx @PSBoundParameters
}
Set-Alias -Name docx-to-latex -Value ConvertTo-LaTeXFromDocx -ErrorAction SilentlyContinue

# Convert EPUB to LaTeX
<#
.SYNOPSIS
    Converts EPUB file to LaTeX.
.DESCRIPTION
    Uses pandoc to convert an EPUB file to LaTeX format.
.PARAMETER InputPath
    The path to the EPUB file.
.PARAMETER OutputPath
    The path for the output LaTeX file. If not specified, uses input path with .tex extension.
#>
function ConvertTo-LaTeXFromEpub {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionInitialized) { Ensure-FileConversion }
    _ConvertTo-LaTeXFromEpub @PSBoundParameters
}
Set-Alias -Name epub-to-latex -Value ConvertTo-LaTeXFromEpub -ErrorAction SilentlyContinue
