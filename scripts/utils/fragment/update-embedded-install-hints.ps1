# One-shot codemod: replace hardcoded embedded install strings with placeholders + expansion.
# Usage: pwsh -NoProfile -File scripts/utils/fragment/update-embedded-install-hints.ps1

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$conversionRoot = Join-Path $repoRoot 'profile.d' 'conversion-modules'

$pythonReplacements = [ordered]@{
    'uv pip install ion-python'                                              = @('ion-python')
    'uv pip install pyreadstat pandas polars'                                = @('pyreadstat', 'pandas', 'polars')
    'uv pip install pyreadstat'                                              = @('pyreadstat')
    'uv pip install python-snappy'                                           = @('python-snappy')
    'uv pip install pyodbc'                                                  = @('pyodbc')
    'uv pip install dbfread'                                                 = @('dbfread')
    'uv pip install dbf'                                                     = @('dbf')
    'uv pip install pyiceberg pyarrow'                                       = @('pyiceberg', 'pyarrow')
    'uv pip install delta-spark pyarrow or uv pip install deltalake pyarrow' = @('delta-spark', 'deltalake', 'pyarrow')
    'uv pip install delta-spark or uv pip install deltalake'                 = @('delta-spark', 'deltalake')
    'uv pip install pandas polars pyarrow'                                   = @('pandas', 'polars', 'pyarrow')
    'uv pip install pandas polars'                                           = @('pandas', 'polars')
    'uv pip install pandas pyarrow'                                          = @('pandas', 'pyarrow')
    'uv pip install polars pyarrow'                                          = @('polars', 'pyarrow')
    'uv pip install pyarrow fastparquet'                                     = @('pyarrow', 'fastparquet')
    'uv pip install pyarrow'                                                 = @('pyarrow')
    'uv pip install fastparquet'                                             = @('fastparquet')
    'uv pip install h5py'                                                    = @('h5py')
    'uv pip install netCDF4'                                                 = @('netCDF4')
    'uv pip install xarray'                                                  = @('xarray')
    'uv pip install scipy'                                                   = @('scipy')
    'uv pip install astropy'                                                 = @('astropy')
    'uv pip install mat73'                                                   = @('mat73')
    'uv pip install pymatreader'                                             = @('pymatreader')
    'uv pip install pyorc'                                                   = @('pyorc')
    'uv pip install thrift'                                                  = @('thrift')
    'uv pip install avro-python3'                                            = @('avro-python3')
    'uv pip install fastavro'                                                = @('fastavro')
    'uv pip install protobuf'                                                = @('protobuf')
    'uv pip install flatbuffers'                                             = @('flatbuffers')
    'uv pip install pycapnp'                                                 = @('pycapnp')
    'uv pip install msgpack'                                                 = @('msgpack')
    'uv pip install cbor2'                                                   = @('cbor2')
    'uv pip install bson'                                                    = @('bson')
    'uv pip install pyiceberg'                                               = @('pyiceberg')
    'Install it with: uv pip install pyiceberg'                                = @('pyiceberg')
    'uv pip install pandas or uv pip install polars'                           = @('pandas', 'polars')
}

$nodeReplacements = [ordered]@{
    'pnpm add -g ubjson'                = @('ubjson')
    'pnpm add -g superjson'             = @('superjson')
    'pnpm add -g parquetjs apache-arrow' = @('parquetjs', 'apache-arrow')
    'pnpm add -g apache-arrow parquetjs' = @('apache-arrow', 'parquetjs')
    'pnpm add -g parquetjs'             = @('parquetjs')
    'pnpm add -g apache-arrow'          = @('apache-arrow')
    'pnpm add -g bson @msgpack/msgpack'  = @('bson', '@msgpack/msgpack')
    'pnpm add -g bson cbor'              = @('bson', 'cbor')
    'pnpm add -g @msgpack/msgpack cbor'  = @('@msgpack/msgpack', 'cbor')
    'pnpm add -g bson'                   = @('bson')
    'pnpm add -g @msgpack/msgpack'       = @('@msgpack/msgpack')
    'pnpm add -g cbor'                   = @('cbor')
    'pnpm add -g avro-js'                = @('avro-js')
    'pnpm add -g avsc'                   = @('avsc')
    'pnpm add -g capnp'                  = @('capnp')
    'pnpm add -g protobufjs'             = @('protobufjs')
    'pnpm add -g flatbuffers'            = @('flatbuffers')
    'pnpm add -g thrift'                 = @('thrift')
    'pnpm add -g capnp-ts'               = @('capnp-ts')
    'pnpm add -g json5'                  = @('json5')
    'pnpm add -g json-extended'          = @('json-extended')
    'Install it with: pnpm add -g parquetjs' = @('parquetjs')
    'Install it with: pnpm add -g apache-arrow' = @('apache-arrow')
    'npm install -g jsbarcode canvas'    = @('jsbarcode', 'canvas')
}

function Get-SortedUniquePackages {
    param([System.Collections.Generic.HashSet[string]]$Set)
    return ($Set | Sort-Object)
}

$updated = 0
Get-ChildItem -LiteralPath $conversionRoot -Recurse -Filter '*.ps1' | ForEach-Object {
    $path = $_.FullName
    $content = Get-Content -LiteralPath $path -Raw
    $original = $content

    $pythonPackages = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $nodePackages = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($entry in $pythonReplacements.GetEnumerator()) {
        if ($content.Contains([string]$entry.Key)) {
            $content = $content.Replace([string]$entry.Key, '__PYTHON_INSTALL_CMD__')
            foreach ($pkg in $entry.Value) { [void]$pythonPackages.Add([string]$pkg) }
        }
    }

    foreach ($entry in $nodeReplacements.GetEnumerator()) {
        if ($content.Contains([string]$entry.Key)) {
            $content = $content.Replace([string]$entry.Key, '__NODE_INSTALL_CMD__')
            foreach ($pkg in $entry.Value) { [void]$nodePackages.Add([string]$pkg) }
        }
    }

    if ($content -eq $original) {
        return
    }

    $content = $content -replace '\(\$pythonScript -replace ''sys\\.argv\\\[4\\\]'', "[^"]+"\)', '$pythonScript'

    if ($content -match '__PYTHON_INSTALL_CMD__' -and $pythonPackages.Count -gt 0) {
        $pkgList = (Get-SortedUniquePackages $pythonPackages) -join "', '"
        $expand = "`$pythonScript = Expand-EmbeddedPythonInstallHints -Script `$pythonScript -PackageNames '$pkgList' -Global"
        $content = [regex]::Replace(
            $content,
            '(?m)^(\s*)Set-Content -LiteralPath \$tempScript -Value \$pythonScript',
            "`$1$expand`n`$1Set-Content -LiteralPath `$tempScript -Value `$pythonScript"
        )
    }

    if ($content -match '__NODE_INSTALL_CMD__' -and $nodePackages.Count -gt 0) {
        $pkgList = (Get-SortedUniquePackages $nodePackages) -join "', '"
        $expand = "`$nodeScript = Expand-EmbeddedNodeInstallHints -Script `$nodeScript -PackageNames '$pkgList' -Global"
        $content = [regex]::Replace(
            $content,
            '(?m)^(\s*)Set-Content -LiteralPath \$tempScript -Value \$nodeScript',
            "`$1$expand`n`$1Set-Content -LiteralPath `$tempScript -Value `$nodeScript"
        )
    }

    Set-Content -LiteralPath $path -Value $content -Encoding UTF8 -NoNewline
    $updated++
    Write-Host "Updated $path"
}

Write-Host "Updated $updated conversion module file(s)."
