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
- `Ensure-FileConversion` — >
- `json-pretty` — >
- `yaml-to-json` — >
- `json-to-yaml` — >
- `to-base64` — >
- `from-base64` — >
- `csv-to-json` — >
- `json-to-csv` — >
- `xml-to-json` — >
- `markdown-to-html` — >
- `html-to-markdown` — >
- `image-convert` — >
- `audio-convert` — >
- `pdf-to-text` — >
- `video-to-audio` — >
- `video-to-gif` — >
- `image-resize` — >
- `pdf-merge` — >
- `epub-to-markdown` — >
- `docx-to-markdown` — >
- `csv-to-yaml` — >
- `yaml-to-csv` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
