# ConvertFrom-HtmlEncoded

## Synopsis

HTML-decodes a string.

## Description

Decodes HTML-encoded strings back to their original form.

## Signature

```powershell
ConvertFrom-HtmlEncoded
```

## Parameters

### -Text

The HTML-encoded text to decode. Can be piped.


## Outputs

System.String The HTML-decoded string.


## Examples

### Example 1

```powershell
"&lt;script&gt;" | ConvertFrom-HtmlEncoded
```

Returns "<script>".

## Aliases

This function has the following aliases:

- `html-decode` - HTML-decodes a string.


## Source

Defined in: ../profile.d/dev-tools-modules/encoding/encoding.ps1
