profile.d/00-bootstrap.ps1
=========================

Purpose
-------

Core bootstrap helpers for profile fragments. Provides essential functions and global state initialization for the PowerShell profile system.

Usage
-----

This fragment initializes global variables and defines core functions used throughout the profile:

- Command availability testing with caching
- Agent mode function and alias registration
- Lazy loading and deprecation helpers
- Fragment warning suppression
- Assumed command management

See the fragment source: `00-bootstrap.ps1` for detailed function documentation.

Dependencies
------------

None explicit; imports the Common.psm1 module if available.

Notes
-----

This is the foundational fragment loaded first (00-). Keep it lightweight and focused on core utilities. All other fragments depend on these helpers.
