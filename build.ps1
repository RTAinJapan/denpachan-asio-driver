<#
.SYNOPSIS
  denpachan-asio-driver.dll をビルドする。

.DESCRIPTION
  Visual Studio の開発者シェルに入り、CMake プリセットで configure / build する。
  ASIO SDK は cmake/FetchAsioSdk.cmake が out/deps に取る。vcpkg は使わない。
  出力: out/build/bin/Release/denpachan-asio-driver.dll (と licenses/)

.EXAMPLE
  ./build.ps1                      # Release
  ./build.ps1 -Config debug
  ./build.ps1 -VersionLabel rc.1   # 版の後ろにラベルを付ける (プレリリース。CI がタグ vX.Y.Z-rc.1 のときに使う)
#>
param(
    [ValidateSet('release', 'debug')]
    [string]$Config = 'release',
    [switch]$Clean,
    [string]$VersionLabel = ''
)
$ErrorActionPreference = 'Stop'

# VS 開発者シェル (cl.exe / cmake / ninja を PATH に入れる)
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { throw 'C++ ツールセット入りの Visual Studio が見つからない' }
    $env:PATH = (Split-Path $vswhere) + ';' + $env:PATH
    Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
    Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null
}

Push-Location $PSScriptRoot
try {
    if ($Clean -and (Test-Path out/build)) { Remove-Item -Recurse -Force out/build }
    # ラベルは毎回渡す (前のビルドのラベルが CMake のキャッシュに残らないように)
    cmake --preset x64 "-DDENPACHAN_VERSION_LABEL=$VersionLabel"
    if ($LASTEXITCODE) { throw 'configure failed' }
    cmake --build --preset $Config
    if ($LASTEXITCODE) { throw 'build failed' }
} finally {
    Pop-Location
}
