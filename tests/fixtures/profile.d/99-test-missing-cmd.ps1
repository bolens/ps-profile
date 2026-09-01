# Try to use a command that doesn't exist.
$result = Get-NonExistentCommand -ErrorAction SilentlyContinue
