# Invoke-FormatConversion

## Synopsis

Executes a format conversion with standardized validation and error handling.

## Description

Provides a standardized way to execute format conversions with: - Input file validation - Tool availability checking - Output path generation - Command execution with error capture - Exit code validation - Comprehensive error handling

## Signature

```powershell
Invoke-FormatConversion
```

## Parameters

### -InputPath

Path to the input file to convert.

### -OutputPath

Optional path for the output file. If not provided, will be generated from InputPath.

### -ToolCommand

Name of the conversion tool command (e.g., 'pandoc', 'ffmpeg', 'magick').

### -ToolArguments

Array of arguments to pass to the tool command.

### -OutputExtension

File extension for output file (e.g., '.html', '.pdf'). Used if OutputPath not provided.

### -InputExtension

File extension of input file (e.g., '.md', '.jpg'). Used for output path generation.

### -InstallHint

Installation hint for missing tool warning.

### -ErrorContext

Context string for error messages (e.g., "Markdown to HTML conversion").

### -ValidateOutput

If specified, validates that output file was created after conversion.


## Outputs

System.Boolean. True if conversion successful, false otherwise.


## Examples

### Example 1

`powershell
Invoke-FormatConversion -InputPath 'document.md' `
            -ToolCommand 'pandoc' `
            -ToolArguments @('-o', 'output.html') `
            -OutputExtension '.html' `
            -InputExtension '.md' `
            -ErrorContext 'Markdown to HTML conversion'
        
        Converts Markdown to HTML using pandoc.
``

## Source

Defined in: ../profile.d/conversion-modules/helpers/ConversionBase.ps1
