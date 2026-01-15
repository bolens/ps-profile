# Archive-WebPage

## Synopsis

Archives web pages.

## Description

Creates standalone HTML archives of web pages using monolith. Preserves page structure, images, and styling.

## Signature

```powershell
Archive-WebPage
```

## Parameters

### -Url

URL of the web page to archive.

### -OutputFile

Path to save the archived HTML file. Defaults to page title with .html extension.


## Examples

### Example 1

`powershell
Archive-WebPage -Url "https://example.com/article"
        
        Archives a web page as standalone HTML.
``

## Source

Defined in: ..\profile.d\content-tools.ps1
