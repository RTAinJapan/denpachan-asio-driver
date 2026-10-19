<#
.SYNOPSIS
  配布用の zip を作る。

.DESCRIPTION
  build.ps1 のあとに実行する。out/dist/denpachan-asio-driver-<版>-win64.zip (DLL、licenses/、README.md) と、
  PDB だけの out/dist/denpachan-asio-driver-<版>-win64-symbols.zip を作る。

.EXAMPLE
  ./tools/package.ps1                      # 版は CMakeLists.txt から、後ろに git の短いハッシュを付ける
  ./tools/package.ps1 -Suffix ''           # ハッシュを付けない
  ./tools/package.ps1 -Suffix rc.1
#>
param(
    [string]$Suffix
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$bin = Join-Path $root 'out/build/bin/Release'
if (-not (Test-Path (Join-Path $bin 'denpachan-asio-driver.dll'))) { throw "先に build.ps1 でビルドする ($bin)" }

$version = (Select-String -Path (Join-Path $root 'CMakeLists.txt') -Pattern 'project\(denpachan-asio-driver .*VERSION ([0-9.]+)').Matches[0].Groups[1].Value
if (-not $PSBoundParameters.ContainsKey('Suffix')) { $Suffix = (git -C $root rev-parse --short HEAD).Trim() }
$name = if ($Suffix) { "denpachan-asio-driver-$version-$Suffix" } else { "denpachan-asio-driver-$version" }

$dist = Join-Path $root 'out/dist'
$stage = Join-Path $dist $name
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item (Join-Path $bin 'denpachan-asio-driver.dll') $stage
Copy-Item (Join-Path $bin 'licenses') $stage -Recurse
Copy-Item (Join-Path $root 'README.md') $stage

# エントリ名を / 区切りにして自分で書く (Compress-Archive は \ を使い、展開するツールによってはフォルダにならない)
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
function New-Zip([string]$zipPath, [System.IO.FileInfo[]]$files, [string]$baseDir, [string]$prefix) {
    $stream = [IO.File]::Open($zipPath, [IO.FileMode]::Create)
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($baseDir.Length).TrimStart('\', '/').Replace('\', '/')
            $entry = if ($prefix) { "$prefix/$rel" } else { $rel }
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entry,
                [IO.Compression.CompressionLevel]::Optimal)
        }
    } finally {
        $archive.Dispose()
        $stream.Dispose()
    }
}

$zip = Join-Path $dist "$name-win64.zip"
$symbols = Join-Path $dist "$name-win64-symbols.zip"
Remove-Item $zip, $symbols -ErrorAction SilentlyContinue
New-Zip $zip (Get-ChildItem $stage -Recurse -File) (Resolve-Path $stage).Path $name
New-Zip $symbols (Get-ChildItem $bin -Filter *.pdb -File) (Resolve-Path $bin).Path ''
Remove-Item -Recurse -Force $stage
Write-Host "package: $zip"
Write-Host "symbols: $symbols"
