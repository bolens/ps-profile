# Save-IsbnCover

## Synopsis

Downloads a book cover image for an ISBN.

## Description

Looks up the ISBN, resolves the cover URL, and saves the image to disk.

## Signature

```powershell
Save-IsbnCover
```

## Parameters

### -Isbn

The ISBN to look up.

### -OutputPath

Destination file path. Defaults to ./<isbn>.jpg in the current directory.

### -Provider

Data provider: Auto, OpenLibrary, GoogleBooks, OpenBD, or LibraryOfCongress.

### -Refresh

Bypass cached lookup results when resolving metadata.

### -PassThru

Returns the saved file path.


## Outputs

System.String. Path to the saved cover image when -PassThru is used.


## Examples

### Example 1

```powershell
Save-IsbnCover -Isbn "978-0-306-40615-7" -OutputPath "./cover.jpg"
```

## Aliases

This function has the following aliases:

- `isbn-cover` - Downloads a book cover image for an ISBN.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
