# Plan

Remove the tracked configuration name from the transient artifact list in
tests/TestSupport/TestMocks.ps1. Add a behavioral fixture in the existing
TestSupport suite and verify preservation with the native no-profile runner.
The change enforces the constitution's safe test environment requirement.
