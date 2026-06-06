# Get-LoremIpsum

## Synopsis

Generates Lorem Ipsum placeholder text.

## Description

Generates Lorem Ipsum placeholder text with specified number of words or paragraphs.

## Signature

```powershell
Get-LoremIpsum
```

## Parameters

### -Words

Number of words to generate. Default is 50.

### -Paragraphs

Number of paragraphs to generate. Default is 1.

### -StartWithLorem

If specified, starts the first paragraph with "Lorem ipsum".


## Outputs

System.String The generated Lorem Ipsum text.


## Examples

### Example 1

`powershell
Get-LoremIpsum -Words 100
    Generates 100 words of Lorem Ipsum text.
``

### Example 2

`powershell
Get-LoremIpsum -Paragraphs 3 -StartWithLorem
    Generates 3 paragraphs starting with "Lorem ipsum".
``

## Aliases

This function has the following aliases:

- `lorem` - Generates Lorem Ipsum placeholder text.


## Source

Defined in: ../profile.d/dev-tools-modules/data/lorem.ps1
