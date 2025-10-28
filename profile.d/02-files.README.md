profile.d/02-files.ps1
======================

Purpose
-------
Consolidated file and listing utilities (json/yaml, eza, bat, navigation)

Usage
-----
See the fragment source: `02-files.ps1` for examples and usage notes.

Functions
---------
- `Ensure-FileHelper` — Lazy bulk initializer for file helpers
- `json-pretty` — Pretty-print JSON
- `yaml-to-json` — Convert YAML to JSON
- `json-to-yaml` — Convert JSON to YAML
- `ll` — List files in a directory
- `la` — List all files including hidden
- `lx` — List files excluding hidden
- `tree` — Display directory tree
- `bat-cat` — cat with syntax highlighting (bat)
- `desktop` — Go to Desktop directory
- `downloads` — Go to Downloads directory
- `docs` — Go to Documents directory
- `head` — Head (first 10 lines) of a file
- `tail` — Tail (last 10 lines) of a file
- `to-base64` — Encode to base64
- `from-base64` — Decode from base64
- `csv-to-json` — Convert CSV to JSON
- `xml-to-json` — Convert XML to JSON
- `file-hash` — Get file hash
- `filesize` — Get file size
- `..` — Up directory
- `...` — Up two directories
- `....` — Up three directories
- `~` — Go to user's Home directory

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

