# Conversion Utilities Enhanced with Error Handling

## Summary

This document tracks conversion utilities that have been enhanced with comprehensive error handling, wide context, and debug-level messaging according to the error handling standard.

## Completed Files

### Core Data Conversion Utilities

1. **`data/core/json.ps1`**

   - Function: `_Format-Json` (JSON pretty-print)
   - Public function: `Format-Json`

2. **`data/core/csv.ps1`**

   - Functions: `_ConvertFrom-CsvToJson`, `_ConvertTo-CsvFromJson`, `_ConvertFrom-CsvToYaml`, `_ConvertFrom-YamlToCsv`
   - Public functions: `ConvertFrom-CsvToJson`, `ConvertTo-CsvFromJson`, `ConvertFrom-CsvToYaml`, `ConvertFrom-YamlToCsv`

3. **`data/core/xml.ps1`**

   - Function: `_ConvertFrom-XmlToJson`
   - Public function: `ConvertFrom-XmlToJson`

4. **`data/core/yaml.ps1`**
   - Functions: `_ConvertFrom-Yaml`, `_ConvertTo-Yaml`
   - Public functions: `ConvertFrom-Yaml`, `ConvertTo-Yaml`

### Structured Data Conversion Utilities

5. **`data/structured/properties.ps1`**

   - Functions: `_ConvertFrom-PropertiesToJson`, `_ConvertTo-PropertiesFromJson`, `_ConvertFrom-PropertiesToYaml`, `_ConvertTo-PropertiesFromYaml`, `_ConvertFrom-PropertiesToIni`, `_ConvertTo-PropertiesFromIni`
   - Public functions: All corresponding public wrappers

6. **`data/structured/ini.ps1`**

   - Functions: `_ConvertFrom-IniToJson`, `_ConvertTo-IniFromJson`, `_ConvertFrom-IniToYaml`, `_ConvertTo-IniFromYaml`, `_ConvertFrom-IniToXml`, `_ConvertTo-IniFromXml`, `_ConvertFrom-IniToToml`, `_ConvertTo-IniFromToml`
   - Public functions: All corresponding public wrappers

7. **`data/structured/cfg.ps1`**

   - Functions: `_ConvertFrom-CfgToJson`, `_ConvertTo-CfgFromJson`, `_ConvertFrom-CfgToYaml`, `_ConvertTo-CfgFromYaml`, `_ConvertFrom-CfgToIni`, `_ConvertTo-CfgFromIni`
   - Public functions: All corresponding public wrappers

8. **`data/structured/toml.ps1`**

   - Functions: `_ConvertFrom-TomlToJson`, `_ConvertTo-TomlFromJson`, `_ConvertFrom-TomlToYaml`, `_ConvertTo-TomlFromYaml`, `_ConvertFrom-TomlToToon`, `_ConvertTo-TomlFromToon`, `_ConvertFrom-TomlToXml`, `_ConvertTo-TomlFromXml`
   - Public functions: All corresponding public wrappers

9. **`data/structured/env.ps1`**

   - Functions: `_ConvertFrom-EnvToJson`, `_ConvertTo-EnvFromJson`, `_ConvertFrom-EnvToYaml`, `_ConvertTo-EnvFromYaml`, `_ConvertFrom-EnvToIni`, `_ConvertTo-EnvFromIni`
   - Public functions: All corresponding public wrappers

10. **`data/structured/jsonc.ps1`**

- Functions: `_ConvertFrom-JsoncToJson`, `_ConvertTo-JsoncFromJson`, `_ConvertFrom-JsoncToYaml`, `_ConvertTo-JsoncFromYaml`
- Public functions: All corresponding public wrappers

11. **`data/structured/hjson.ps1`**

- Functions: `_ConvertFrom-HjsonToJson`, `_ConvertTo-HjsonFromJson`, `_ConvertFrom-HjsonToYaml`, `_ConvertTo-HjsonFromYaml`
- Public functions: All corresponding public wrappers

12. **`data/base64/base64.ps1`**

- Functions: `_ConvertTo-Base64`, `_ConvertFrom-Base64`
- Public functions: `ConvertTo-Base64`, `ConvertFrom-Base64`

### Compression Conversion Utilities

13. **`data/compression/gzip.ps1`**

- Functions: `_Compress-Gzip`, `_Decompress-Gzip`, `_Compress-Zlib`, `_Decompress-Zlib`
- Public functions: `Compress-Gzip`, `Expand-Gzip`, `Compress-Zlib`, `Expand-Zlib`

### Extended JSON Conversion Utilities

14. **`data/core/json-extended.ps1`**

- Functions: `_ConvertFrom-Json5ToJson`, `_ConvertTo-Json5FromJson`, `_ConvertFrom-JsonLToJson`, `_ConvertTo-JsonLFromJson`
- Public functions: All corresponding public wrappers

## Enhancements Applied

Each function now includes:

1. **Debug Level Parsing** - Parsed once at function start
2. **Level 1 Debug Messages** - Basic operation start with input path
3. **Level 2 Debug Messages** - Timing, file sizes, operation context
4. **Level 3 Debug Messages** - Performance breakdown with detailed metrics
5. **Enhanced Error Context** - Includes:
   - Input/output paths
   - File sizes (bytes)
   - Error types
   - Exit codes (for external tools like Python, yq)
   - Line counts, property counts, section counts (where applicable)
6. **Error Debug Messages** - Level 2 shows error types, Level 3 shows stack traces

## Pattern

All updated functions follow this consistent pattern:

```powershell
# Parse debug level once at function start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled
}

try {
    # Level 1: Basic operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[operation.name] Starting conversion: $InputPath"
    }

    $convStartTime = Get-Date
    # ... conversion logic ...
    $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds

    # Level 2: Timing information
    if ($debugLevel -ge 2) {
        Write-Verbose "[operation.name] Conversion completed in ${convDuration}ms"
    }

    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        Write-Host "  [operation.name] Performance details" -ForegroundColor DarkGray
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'operation.name' -Context @{
            input_path = $InputPath
            output_path = $OutputPath
            input_size_bytes = $inputSize
            error_type = $_.Exception.GetType().FullName
        }
    }

    # Level 2: Error details
    if ($debugLevel -ge 2) {
        Write-Verbose "[operation.name] Error type: $($_.Exception.GetType().FullName)"
    }

    # Level 3: Stack trace
    if ($debugLevel -ge 3) {
        Write-Host "  [operation.name] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    }

    throw
}
```

## Total Functions Enhanced

- **14 files** completed
- **62+ conversion functions** enhanced
- **44+ public wrapper functions** enhanced
