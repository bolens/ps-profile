# ConvertTo-HtmlEncoded

## Synopsis

HTML-encodes a string.

## Description

Encodes special characters in a string for safe use in HTML.

## Signature

```powershell
ConvertTo-HtmlEncoded
```

## Parameters

### -Text

The text to encode. Can be piped.


## Outputs

System.String The HTML-encoded string.


## Examples

### Example 1

`powershell
"<script>" | ConvertTo-HtmlEncoded
    Returns "&lt;script&gt;".
``

## Aliases

This function has the following aliases:

- `html-encode` - HTML-encodes a string.


## Source

Defined in: ../profile.d/dev-tools-modules/encoding/encoding.ps1
