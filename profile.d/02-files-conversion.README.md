profile.d/02-files-conversion.ps1
=================================

Purpose
-------
File conversion utilities

Usage
-----
See the fragment source: `02-files-conversion.ps1` for examples and usage notes.

Functions
---------
- `Ensure-FileConversion` — Initializes file conversion utility functions on first use.
- `Format-Json` — Pretty-prints JSON data.
- `ConvertFrom-Yaml` — Converts YAML to JSON format.
- `ConvertTo-Yaml` — Converts JSON to YAML format.
- `ConvertTo-Base64` — Encodes input to base64 format.
- `ConvertFrom-Base64` — Decodes base64 input to text.
- `ConvertFrom-CsvToJson` — Converts CSV file to JSON format.
- `ConvertTo-CsvFromJson` — Converts JSON file to CSV format.
- `ConvertFrom-XmlToJson` — Converts XML file to JSON format.
- `ConvertTo-HtmlFromMarkdown` — Converts Markdown file to HTML.
- `ConvertFrom-HtmlToMarkdown` — Converts HTML file to Markdown.
- `Convert-Image` — Converts image file formats.
- `Convert-Audio` — Converts audio file formats.
- `ConvertFrom-PdfToText` — Extracts text from PDF file.
- `ConvertFrom-VideoToAudio` — Extracts audio from video file.
- `ConvertFrom-VideoToGif` — Converts video to GIF.
- `Resize-Image` — Resizes an image.
- `Merge-Pdf` — Merges multiple PDF files.
- `ConvertFrom-EpubToMarkdown` — Converts EPUB file to Markdown.
- `ConvertFrom-DocxToMarkdown` — Converts DOCX file to Markdown.
- `ConvertFrom-CsvToYaml` — Converts CSV file to YAML format.
- `ConvertFrom-YamlToCsv` — Converts YAML file to CSV format.

Aliases
-------
- `json-pretty` — Pretty-prints JSON data. (alias for `Format-Json`)
- `yaml-to-json` — YAML to JSON (alias for `ConvertFrom-Yaml`)
- `json-to-yaml` — JSON to YAML (alias for `ConvertTo-Yaml`)
- `to-base64` — Base64 encode (alias for `ConvertTo-Base64`)
- `from-base64` — Base64 decode (alias for `ConvertFrom-Base64`)
- `csv-to-json` — CSV to JSON (alias for `ConvertFrom-CsvToJson`)
- `json-to-csv` — JSON to CSV (alias for `ConvertTo-CsvFromJson`)
- `xml-to-json` — XML to JSON (alias for `ConvertFrom-XmlToJson`)
- `markdown-to-html` — Markdown to HTML (alias for `ConvertTo-HtmlFromMarkdown`)
- `html-to-markdown` — HTML to Markdown (alias for `ConvertFrom-HtmlToMarkdown`)
- `image-convert` — Image convert (alias for `Convert-Image`)
- `audio-convert` — Audio convert (alias for `Convert-Audio`)
- `pdf-to-text` — PDF to text (alias for `ConvertFrom-PdfToText`)
- `video-to-audio` — Video to audio (alias for `ConvertFrom-VideoToAudio`)
- `video-to-gif` — Video to GIF (alias for `ConvertFrom-VideoToGif`)
- `image-resize` — Image resize (alias for `Resize-Image`)
- `pdf-merge` — PDF merge (alias for `Merge-Pdf`)
- `epub-to-markdown` — EPUB to Markdown (alias for `ConvertFrom-EpubToMarkdown`)
- `docx-to-markdown` — DOCX to Markdown (alias for `ConvertFrom-DocxToMarkdown`)
- `csv-to-yaml` — CSV to YAML (alias for `ConvertFrom-CsvToYaml`)
- `yaml-to-csv` — YAML to CSV (alias for `ConvertFrom-YamlToCsv`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
