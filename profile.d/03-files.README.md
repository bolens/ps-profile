profile.d/03-files.ps1
======================

Purpose
-------
Consolidated file and listing utilities (json/yaml, eza, bat, navigation)

Usage
-----
See the fragment source: `03-files.ps1` for examples and usage notes.

Functions
---------
- `Ensure-FileHelper` — Lazy bulk initializer for file helpers
- `json-pretty` — Lightweight stubs that ensure the real implementations are created on first use
- `yaml-to-json`
- `json-to-yaml`
- `ll`
- `la`
- `lx`
- `tree`
- `bat-cat`
- `desktop`
- `downloads`
- `docs`
- `head`
- `tail`
- `to-base64`
- `from-base64`
- `csv-to-json`
- `xml-to-json`
- `file-hash`
- `filesize`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
