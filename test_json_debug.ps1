$jsonString = '[{"name":"test","value":123}]'
Write-Host "Single element array:"
$data = $jsonString | ConvertFrom-Json
Write-Host "Type: $($data.GetType().FullName)"
Write-Host "Is array: $($data -is [array])"

$jsonString2 = '[{"name":"test","value":123},{"name":"test2","value":456}]'
Write-Host "Multiple element array:"
$data2 = $jsonString2 | ConvertFrom-Json
Write-Host "Type: $($data2.GetType().FullName)"
Write-Host "Is array: $($data2 -is [array])"
Write-Host "Length: $($data2.Length)"
