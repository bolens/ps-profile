# ===============================================
# XML conversion helper utilities
# XML ↔ JSON conversion helpers
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
        # Always return an object, even for text-only elements
        return [PSCustomObject]$obj
    }
}

# JSON to XML helper function
<#
.SYNOPSIS
    Converts a JSON object to XML format.
.DESCRIPTION
    Converts a PowerShell object (from JSON) to XML format.
.PARAMETER JsonObject
    The PowerShell object to convert to XML.
.PARAMETER RootName
    The root element name for the XML document.
.OUTPUTS
    System.Xml.XmlDocument representing the XML structure.
#>
function Convert-JsonToXml {
    param(
        [Parameter(Mandatory)]
        $JsonObject,
        [string]$RootName = 'root'
    )

    # Helper function to sanitize XML element names (XML names cannot contain spaces or certain characters)
    function Sanitize-XmlName {
        param([string]$Name)
        if ([string]::IsNullOrWhiteSpace($Name)) { return 'element' }
        # Replace invalid XML name characters with underscores
        # XML names must start with a letter or underscore, and can contain letters, digits, hyphens, underscores, and periods
        $sanitized = $Name -replace '^[^a-zA-Z_]', '_' -replace '[^\w\-\.]', '_'
        # Ensure it doesn't start with a number
        if ($sanitized -match '^\d') { $sanitized = '_' + $sanitized }
        return $sanitized
    }

    $xmlDoc = New-Object System.Xml.XmlDocument
    $sanitizedRootName = Sanitize-XmlName $RootName
    $root = $xmlDoc.CreateElement($sanitizedRootName)
    $xmlDoc.AppendChild($root) | Out-Null

    function Add-ToXml {
        param($Parent, $Data, $Name)

        if ($Data -is [PSCustomObject] -or $Data -is [hashtable]) {
            foreach ($prop in $Data.PSObject.Properties) {
                $sanitizedName = Sanitize-XmlName $prop.Name
                $elem = $xmlDoc.CreateElement($sanitizedName)
                # Store original name as attribute if it was sanitized
                if ($sanitizedName -ne $prop.Name) {
                    $elem.SetAttribute('_originalName', $prop.Name) | Out-Null
                }
                Add-ToXml -Parent $elem -Data $prop.Value -Name $prop.Name
                $Parent.AppendChild($elem) | Out-Null
            }
        }
        elseif ($Data -is [array]) {
            $sanitizedName = Sanitize-XmlName $Name
            foreach ($item in $Data) {
                $elem = $xmlDoc.CreateElement($sanitizedName)
                # Store original name as attribute if it was sanitized
                if ($sanitizedName -ne $Name) {
                    $elem.SetAttribute('_originalName', $Name) | Out-Null
                }
                Add-ToXml -Parent $elem -Data $item -Name $Name
                $Parent.AppendChild($elem) | Out-Null
            }
        }
        elseif ($null -ne $Data) {
            $Parent.InnerText = $Data.ToString()
        }
    }

    Add-ToXml -Parent $root -Data $JsonObject -Name $RootName
    return $xmlDoc
}

