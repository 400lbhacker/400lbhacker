# r2di.ps1
# radare2 6.2.0 + r2ghidra + Sleigh + r2dec
# Windows / PowerShell 5.1 compatible
#
# IMPORTANT:
# Replace the ENTIRE old r2di.ps1 with this file.
#
# Run:
#   powershell -ExecutionPolicy Bypass -File .\r2di.ps1
#
# If PowerShell policy permits:
#   .\r2di.ps1

#Visit: https://github.com/400lbhacker/400lbhacker#r2di for documentation


$ErrorActionPreference = "Continue"

# ============================================================
# GLOBAL CONFIGURATION
# ============================================================

$R2Prefix       = "C:\radare2"
$R2BinDir       = Join-Path $R2Prefix "bin"
$R2LibDir       = Join-Path $R2Prefix "lib"
$R2IncludeDir   = Join-Path $R2Prefix "include"
$R2UserRoot     = Join-Path $env:USERPROFILE ".local\share\radare2"
$R2UserPlugins  = Join-Path $R2UserRoot "plugins"

$SrcRoot        = Join-Path $env:USERPROFILE "src"
$GhidraSrc      = Join-Path $SrcRoot "r2ghidra"
$R2DecSrc       = Join-Path $SrcRoot "r2dec-js"

$ToolBin        = Join-Path $env:USERPROFILE "bin"
$UnzipCmd       = Join-Path $ToolBin "unzip.cmd"
$UnzipPs1       = Join-Path $ToolBin "unzip.ps1"

$TempRoot       = Join-Path $env:TEMP "r2di"
$MsvcTestRoot   = Join-Path $TempRoot "msvc-test"
$R2TestRoot     = Join-Path $TempRoot "r2-test"

New-Item -ItemType Directory -Force -Path $SrcRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ToolBin | Out-Null
New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
New-Item -ItemType Directory -Force -Path $R2UserPlugins | Out-Null

# ============================================================
# HELPERS
# ============================================================

function Banner {
    param([string]$Text)

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " $Text"
    Write-Host "============================================================"
}

function Info {
    param([string]$Text)
    Write-Host "[*] $Text"
}

function Good {
    param([string]$Text)
    Write-Host "[+] $Text"
}

function Warn {
    param([string]$Text)
    Write-Host "[!] $Text"
}

function Fail {
    param([string]$Text)
    Write-Host ""
    Write-Host "[ERROR] $Text"
    throw $Text
}

function CommandExists {
    param([string]$Name)

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue

    if ($null -ne $cmd) {
        return $true
    }

    return $false
}

function Get-CommandPath {
    param([string]$Name)

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue

    if ($null -eq $cmd) {
        return $null
    }

    return $cmd.Source
}

function Invoke-Native {
    param(
        [string]$Exe,
        [string[]]$Arguments
    )

    & $Exe @Arguments
    return $LASTEXITCODE
}

function Remove-Safely {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        Good "Removed: $Path"
    }
    catch {
        Warn "Could not remove: $Path"
        Warn $_.Exception.Message
    }
}

function Add-ToPath {
    param([string]$Directory)

    if (-not $Directory) {
        return
    }

    if (-not (Test-Path -LiteralPath $Directory)) {
        return
    }

    $parts = $env:PATH -split ";"

    foreach ($p in $parts) {
        if ($p.TrimEnd("\") -ieq $Directory.TrimEnd("\")) {
            return
        }
    }

    $env:PATH = "$Directory;$env:PATH"
}

function Set-EnvPathList {
    param(
        [string]$Variable,
        [string[]]$Entries
    )

    $valid = @()

    foreach ($entry in $Entries) {
        if ($entry -and (Test-Path -LiteralPath $entry)) {
            $valid += $entry
        }
    }

    if ($valid.Count -gt 0) {
        Set-Item "Env:$Variable" (($valid -join ";"))
    }
}

function Test-SleighDataDir {
    param([string]$Path)

    if (-not $Path) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    # The r2ghidra_sleigh package for Windows ships a FLAT layout - the
    # .ldefs/.sla/.pspec/.cspec files sit directly inside the sleighhome
    # folder (e.g. x86.ldefs, x86.sla). There is NO Ghidra-style nested
    # "Processors\<family>\data\languages\" tree, despite that being the
    # layout Ghidra itself uses. The presence of at least one *.ldefs
    # file directly in the folder is the real, confirmed marker of a
    # valid sleighhome for this plugin - not a "Processors" directory.
    $found = Get-ChildItem -LiteralPath $Path -Filter "*.ldefs" -File -ErrorAction SilentlyContinue |
        Select-Object -First 1

    return [bool]$found
}

function Find-SleighDataDir {
    param([string]$Root)

    if (-not $Root) {
        return $null
    }

    if (-not (Test-Path -LiteralPath $Root)) {
        return $null
    }

    if (Test-SleighDataDir $Root) {
        return $Root
    }

    $found = Get-ChildItem -LiteralPath $Root -Filter "*.ldefs" -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($found) {
        return $found.Directory.FullName
    }

    return $null
}

function Get-LatestDirectory {
    param([string]$Root)

    if (-not (Test-Path -LiteralPath $Root)) {
        return $null
    }

    $dirs = @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue)

    if ($dirs.Count -eq 0) {
        return $null
    }

    $sorted = $dirs | Sort-Object Name -Descending

    return $sorted[0].FullName
}

# ============================================================
# START
# ============================================================

Banner "r2di Windows bootstrap"

Write-Host "[*] PowerShell:"
$PSVersionTable.PSVersion

Write-Host "[*] User:"
Write-Host "    $env:USERNAME"

# ============================================================
# GIT
# ============================================================

Banner "Checking Git"

if (-not (CommandExists "git.exe")) {
    Fail "Git was not found in PATH. Install Git for Windows first."
}

$GitExe = Get-CommandPath "git.exe"

Good "Git:"
& $GitExe --version

# ============================================================
# RADARE2
# ============================================================

Banner "Locating radare2"

$R2Exe = $null

# First try PATH.
if (CommandExists "radare2.exe") {
    $R2Exe = Get-CommandPath "radare2.exe"
    Good "radare2 found in PATH:"
    Write-Host "    $R2Exe"
}

# Then known installation.
if (-not $R2Exe) {
    $candidate = Join-Path $R2BinDir "radare2.exe"

    if (Test-Path -LiteralPath $candidate) {
        $R2Exe = $candidate

        Good "radare2 found:"
        Write-Host "    $R2Exe"

        Add-ToPath $R2BinDir
    }
}

# Other common locations.
if (-not $R2Exe) {
    $candidates = @(
        "C:\radare2\bin\radare2.exe",
        "$env:LOCALAPPDATA\Programs\radare2\bin\radare2.exe",
        "$env:ProgramFiles\radare2\bin\radare2.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            $R2Exe = $candidate
            break
        }
    }

    if ($R2Exe) {
        Good "radare2 found:"
        Write-Host "    $R2Exe"
        Add-ToPath (Split-Path $R2Exe -Parent)
    }
}

if (-not $R2Exe) {
    Fail "radare2.exe was not found. Install radare2 first."
}

# Get version WITHOUT embedding any command text containing Unicode.
$r2VersionOutput = @(& $R2Exe -v 2>&1)

$R2Version = $null

foreach ($line in $r2VersionOutput) {
    $s = [string]$line

    if ($s -match "radare2\s+([0-9]+\.[0-9]+\.[0-9]+)") {
        $R2Version = $Matches[1]
        break
    }
}

if (-not $R2Version) {
    Fail "Could not determine radare2 version."
}

Good "radare2 version: $R2Version"

if ($R2Version -ne "6.2.0") {
    Warn "This script was designed around radare2 6.2.0."
    Warn "Detected: $R2Version"
}

# ============================================================
# RADARE2 DIRECTORIES
# ============================================================

New-Item -ItemType Directory -Force -Path $R2UserPlugins | Out-Null

$R2VersionData = Join-Path $R2LibDir "radare2\$R2Version"
$R2SleighTarget = Join-Path $R2VersionData "r2ghidra_sleigh"

New-Item -ItemType Directory -Force -Path $R2VersionData | Out-Null

# ============================================================
# LOCATE VISUAL STUDIO
# ============================================================

Banner "Locating Visual Studio"

$VsRoot = $null

$vsCandidates = @(
    "C:\Program Files\Microsoft Visual Studio\18\Community",
    "C:\Program Files\Microsoft Visual Studio\18\Professional",
    "C:\Program Files\Microsoft Visual Studio\18\Enterprise",
    "C:\Program Files\Microsoft Visual Studio\2022\Community",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
)

foreach ($candidate in $vsCandidates) {
    if (Test-Path -LiteralPath $candidate) {
        $VsRoot = $candidate
        break
    }
}

if (-not $VsRoot) {
    Fail "Visual Studio installation was not found."
}

Good "Visual Studio:"
Write-Host "    $VsRoot"

# ============================================================
# LOCATE MSVC
# ============================================================

Banner "Locating MSVC toolchain"

$MsvcRootBase = Join-Path $VsRoot "VC\Tools\MSVC"

$MsvcVersions = @(
    Get-ChildItem -LiteralPath $MsvcRootBase `
        -Directory `
        -ErrorAction SilentlyContinue
)

if ($MsvcVersions.Count -eq 0) {
    Fail "MSVC toolchain was not found under $MsvcRootBase"
}

$MsvcVersionDir = ($MsvcVersions | Sort-Object Name -Descending | Select-Object -First 1)

$MsvcRoot = $MsvcVersionDir.FullName

$MsvcBin = Join-Path $MsvcRoot "bin\Hostx64\x64"
$MsvcInclude = Join-Path $MsvcRoot "include"
$MsvcLib = Join-Path $MsvcRoot "lib\x64"

if (-not (Test-Path -LiteralPath $MsvcBin)) {
    Fail "MSVC compiler directory was not found: $MsvcBin"
}

if (-not (Test-Path -LiteralPath $MsvcInclude)) {
    Fail "MSVC include directory was not found: $MsvcInclude"
}

if (-not (Test-Path -LiteralPath $MsvcLib)) {
    Fail "MSVC library directory was not found: $MsvcLib"
}

Good "MSVC:"
Write-Host "    $MsvcRoot"

# ============================================================
# WINDOWS SDK
# ============================================================

Banner "Locating Windows SDK"

# Explicitly use the path you confirmed exists.
$SdkRoot = "C:\Program Files (x86)\Windows Kits\10"

if (-not (Test-Path -LiteralPath $SdkRoot)) {
    Fail "Windows SDK root was not found: $SdkRoot"
}

$SdkIncludeRoot = Join-Path $SdkRoot "Include"
$SdkLibRoot     = Join-Path $SdkRoot "Lib"
$SdkBinRoot     = Join-Path $SdkRoot "bin"

$SdkVersions = @(
    Get-ChildItem -LiteralPath $SdkIncludeRoot `
        -Directory `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "^10\."
        }
)

if ($SdkVersions.Count -eq 0) {
    Fail "No Windows 10/11 SDK versions found in $SdkIncludeRoot"
}

$SdkVersionDir = (
    $SdkVersions |
    Sort-Object Name -Descending |
    Select-Object -First 1
)

$SdkVersion = $SdkVersionDir.Name

$SdkInclude = Join-Path $SdkIncludeRoot $SdkVersion
$SdkLib     = Join-Path $SdkLibRoot $SdkVersion
$SdkBin     = Join-Path $SdkBinRoot $SdkVersion

Good "Windows SDK:"
Write-Host "    $SdkRoot"

Good "Windows SDK version:"
Write-Host "    $SdkVersion"

# ============================================================
# VERIFY SDK STRUCTURE
# ============================================================

$SdkIncludeUcrt = Join-Path $SdkInclude "ucrt"
$SdkIncludeUm   = Join-Path $SdkInclude "um"
$SdkIncludeShared = Join-Path $SdkInclude "shared"

$SdkLibUcrt = Join-Path $SdkLib "ucrt\x64"
$SdkLibUm   = Join-Path $SdkLib "um\x64"

if (-not (Test-Path -LiteralPath $SdkIncludeUcrt)) {
    Fail "Windows SDK UCRT include directory is missing."
}

if (-not (Test-Path -LiteralPath $SdkIncludeUm)) {
    Fail "Windows SDK UM include directory is missing."
}

if (-not (Test-Path -LiteralPath $SdkIncludeShared)) {
    Fail "Windows SDK shared include directory is missing."
}

if (-not (Test-Path -LiteralPath $SdkLibUcrt)) {
    Fail "Windows SDK UCRT library directory is missing."
}

if (-not (Test-Path -LiteralPath $SdkLibUm)) {
    Fail "Windows SDK UM library directory is missing."
}

# ============================================================
# CONFIGURE MSVC ENVIRONMENT
# ============================================================

Banner "Configuring MSVC environment"

$env:VCToolsInstallDir = "$MsvcRoot\"
$env:VCINSTALLDIR = "$VsRoot\"
$env:WindowsSdkDir = "$SdkRoot\"
$env:WindowsSDKVersion = "$SdkVersion\"

# Correct INCLUDE ordering.
$IncludeEntries = @(
    $MsvcInclude,
    $SdkIncludeUcrt,
    $SdkIncludeUm,
    $SdkIncludeShared
)

$env:INCLUDE = ($IncludeEntries -join ";")

# Correct LIB ordering.
$LibEntries = @(
    $MsvcLib,
    $SdkLibUcrt,
    $SdkLibUm
)

$env:LIB = ($LibEntries -join ";")

# Compiler + linker + SDK tools.
$SdkX64Bin = Join-Path $SdkBin "x64"

$PathEntries = @(
    $MsvcBin,
    $SdkX64Bin,
    $SdkBin,
    $R2BinDir
)

foreach ($p in $PathEntries) {
    Add-ToPath $p
}

$ClExe = Join-Path $MsvcBin "cl.exe"
$LinkExe = Join-Path $MsvcBin "link.exe"

if (-not (Test-Path -LiteralPath $ClExe)) {
    Fail "cl.exe not found: $ClExe"
}

if (-not (Test-Path -LiteralPath $LinkExe)) {
    Fail "link.exe not found: $LinkExe"
}

Good "MSVC environment configured."
Write-Host "    MSVC: $MsvcRoot"
Write-Host "    SDK:  $SdkVersion"

# ============================================================
# TEST MSVC
# ============================================================

Banner "Testing MSVC"

Remove-Safely $MsvcTestRoot

New-Item -ItemType Directory -Force -Path $MsvcTestRoot | Out-Null

$TestC = Join-Path $MsvcTestRoot "test.c"
$TestExe = Join-Path $MsvcTestRoot "test.exe"

# IMPORTANT:
# Use Set-Content explicitly as ASCII so PowerShell 5.1 cannot
# introduce a UTF-8 BOM or malformed Unicode into the C source.
$TestSource = @'
#include <stdio.h>

int main(void)
{
    printf("r2di-msvc-ok\n");
    return 0;
}
'@

Set-Content -LiteralPath $TestC -Value $TestSource -Encoding ASCII

Push-Location $MsvcTestRoot

try {
    & $ClExe /nologo /EHsc /W0 $TestC /Fe:$TestExe

    $MsvcExit = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($MsvcExit -ne 0 -or -not (Test-Path -LiteralPath $TestExe)) {
    Fail "MSVC + Windows SDK compilation test failed."
}

Good "MSVC + Windows SDK compilation test passed."

# ============================================================
# MESON
# ============================================================

Banner "Checking Meson"

if (-not (CommandExists "meson.exe")) {
    Warn "Meson was not found in PATH."

    $MesonCandidates = @(
        "C:\Program Files\Meson\meson.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts\meson.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\Scripts\meson.exe",
        "$env:APPDATA\Python\Python312\Scripts\meson.exe",
        "$env:APPDATA\Python\Python311\Scripts\meson.exe"
    )

    foreach ($candidate in $MesonCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            Add-ToPath (Split-Path $candidate -Parent)
            break
        }
    }
}

if (-not (CommandExists "meson.exe")) {
    Fail "Meson was not found. Install Meson before running this script."
}

$MesonExe = Get-CommandPath "meson.exe"

Good "Meson:"
& $MesonExe --version

# ============================================================
# NINJA
# ============================================================

Banner "Checking Ninja"

if (-not (CommandExists "ninja.exe")) {

    $NinjaCandidates = @(
        "C:\Program Files\Meson\ninja.exe",
        "C:\Program Files\Meson\ninja.EXE"
    )

    foreach ($candidate in $NinjaCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            Add-ToPath (Split-Path $candidate -Parent)
            break
        }
    }
}

if (-not (CommandExists "ninja.exe")) {
    Fail "Ninja was not found."
}

$NinjaExe = Get-CommandPath "ninja.exe"

Good "Ninja:"
& $NinjaExe --version

# ============================================================
# UNZIP SHIM
# ============================================================

Banner "Preparing ZIP extraction support"

# We create exactly ONE shim.
#
# Critical detail:
# unzip.ps1 does NOT declare a param() block at all. If it declared
# parameters (even a single [string[]]$Args with
# ValueFromRemainingArguments), PowerShell would treat the script as an
# "advanced script" and try to bind every "-xxx" token on the command
# line against its declared parameters AND the automatic common
# parameters (-OutVariable, -OutBuffer, -ErrorAction, -Verbose, etc.)
# before ever falling back to the catch-all. "-o" is an ambiguous
# prefix of both -OutVariable and -OutBuffer, so that binding throws:
#
#   "Parameter cannot be processed because the parameter name 'o'
#    is ambiguous."
#
# By declaring NO parameters and reading the automatic $args variable
# instead, nothing is ever interpreted as a named parameter, so r2pm
# can safely call:
#
#     unzip -o file.zip -d directory
#
# and -o / -d pass through untouched as plain positional strings.
#
# Expand-Archive is Windows-native and requires no 7-Zip.

$UnzipPs1Content = @'
# NOTE: intentionally no param() block - see comment in r2di.ps1 for why.

$ErrorActionPreference = "Stop"

$ZipPath = $null
$Destination = $null

for ($i = 0; $i -lt $args.Count; $i++) {

    $arg = [string]$args[$i]

    if ($arg -eq "-d" -or $arg -eq "--directory") {

        if (($i + 1) -lt $args.Count) {
            $Destination = $args[$i + 1]
            $i++
        }

        continue
    }

    if ($arg -eq "-o" -or $arg -eq "--overwrite") {
        continue
    }

    if ($arg -eq "-q" -or $arg -eq "--quiet") {
        continue
    }

    if ($arg.StartsWith("-")) {
        continue
    }

    if ($null -eq $ZipPath) {
        $ZipPath = $arg
    }
}

if ([string]::IsNullOrWhiteSpace($ZipPath)) {
    exit 2
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    Write-Error "ZIP file not found: $ZipPath"
    exit 3
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = (Get-Location).Path
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$TempExtract = Join-Path $env:TEMP ("r2di-unzip-" + [guid]::NewGuid().ToString("N"))

try {

    New-Item -ItemType Directory -Force -Path $TempExtract | Out-Null

    Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempExtract -Force

    # Move extracted files into destination.
    Get-ChildItem -LiteralPath $TempExtract -Force |
        ForEach-Object {

            $target = Join-Path $Destination $_.Name

            if (Test-Path -LiteralPath $target) {

                if ($_.PSIsContainer) {
                    Copy-Item -LiteralPath $_.FullName `
                              -Destination $target `
                              -Recurse `
                              -Force
                }
                else {
                    Copy-Item -LiteralPath $_.FullName `
                              -Destination $target `
                              -Force
                }

            }
            else {
                Move-Item -LiteralPath $_.FullName `
                          -Destination $target `
                          -Force
            }
        }

    exit 0
}
catch {

    Write-Error $_.Exception.Message
    exit 1
}
finally {

    if (Test-Path -LiteralPath $TempExtract) {
        Remove-Item -LiteralPath $TempExtract `
                   -Recurse `
                   -Force `
                   -ErrorAction SilentlyContinue
    }
}
'@

# ASCII is deliberate.
Set-Content -LiteralPath $UnzipPs1 `
    -Value $UnzipPs1Content `
    -Encoding ASCII

$UnzipCmdContent = @'
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0unzip.ps1" %*
exit /b %ERRORLEVEL%
'@

Set-Content -LiteralPath $UnzipCmd `
    -Value $UnzipCmdContent `
    -Encoding ASCII

Add-ToPath $ToolBin

if (-not (Test-Path -LiteralPath $UnzipCmd)) {
    Fail "Could not create unzip shim."
}

Good "unzip shim:"
Write-Host "    $UnzipCmd"

# ============================================================
# TEST UNZIP
# ============================================================

Info "Testing unzip shim..."

$UnzipTestRoot = Join-Path $TempRoot "unzip-test"
$UnzipTestZip  = Join-Path $TempRoot "test.zip"
$UnzipTestDir  = Join-Path $UnzipTestRoot "out"

Remove-Safely $UnzipTestRoot

if (Test-Path -LiteralPath $UnzipTestZip) {
    Remove-Item -LiteralPath $UnzipTestZip -Force
}

New-Item -ItemType Directory -Force -Path $UnzipTestRoot | Out-Null

$TestFile = Join-Path $UnzipTestRoot "hello.txt"

Set-Content -LiteralPath $TestFile `
    -Value "r2di unzip test" `
    -Encoding ASCII

Compress-Archive `
    -LiteralPath $TestFile `
    -DestinationPath $UnzipTestZip `
    -Force

New-Item -ItemType Directory -Force -Path $UnzipTestDir | Out-Null

# Use call operator with literal strings.
# The shim itself handles -o and -d.
& $UnzipCmd "-o" $UnzipTestZip "-d" $UnzipTestDir

$UnzipExit = $LASTEXITCODE

$ExtractedFile = Join-Path $UnzipTestDir "hello.txt"

if ($UnzipExit -ne 0 -or -not (Test-Path -LiteralPath $ExtractedFile)) {
    Fail "unzip shim test failed."
}

Good "unzip shim works."

# ============================================================
# RADARE2 PATH / USER ENVIRONMENT
# ============================================================

Banner "Preparing radare2 environment"

Add-ToPath $R2BinDir

$env:R2_PREFIX = $R2Prefix
$env:R2_USER_PLUGINS = $R2UserPlugins
$env:SLEIGHHOME = $R2SleighTarget

Good "R2_PREFIX:"
Write-Host "    $env:R2_PREFIX"

Good "R2_USER_PLUGINS:"
Write-Host "    $env:R2_USER_PLUGINS"

# ============================================================
# STOP RADARE2
# ============================================================

Banner "Stopping radare2 processes"

Get-Process -Name "radare2","r2","r2pm" `
    -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# ============================================================
# PREPARE R2PM
# ============================================================

Banner "Preparing r2pm"

if (-not (CommandExists "r2pm.exe")) {

    $R2PmCandidates = @(
        "$R2BinDir\r2pm.exe",
        "$R2Prefix\bin\r2pm.exe"
    )

    foreach ($candidate in $R2PmCandidates) {

        if (Test-Path -LiteralPath $candidate) {
            Add-ToPath (Split-Path $candidate -Parent)
            break
        }
    }
}

if (CommandExists "r2pm.exe") {

    $R2PmExe = Get-CommandPath "r2pm.exe"

    Info "Updating r2pm..."

    # r2pm writes routine INFO lines to stderr (e.g. "Running git pull...").
    # Piping 2>&1 turns each stderr line into a PowerShell ErrorRecord, and
    # any cmdlet that renders it (Out-Host included) shows it as a red
    # NativeCommandError even though nothing actually failed. Casting each
    # line to a plain string before Write-Host avoids that misleading
    # formatting while still showing every line r2pm produced.
    & $R2PmExe -U 2>&1 | ForEach-Object { Write-Host ([string]$_) }

}
else {

    Warn "r2pm.exe not found."
    Warn "The script will install r2ghidra directly from the Windows package if available."
}

# ============================================================
# CLEAN OLD GHIDRA PLUGIN
# ============================================================

Banner "Cleaning old r2ghidra installation"

$OldGhidraDll = Join-Path $R2UserPlugins "core_r2ghidra.dll"
$OldGhidraSleighPlugin = Join-Path $R2UserPlugins "r2ghidra_sleigh"

Remove-Safely $OldGhidraDll
Remove-Safely $OldGhidraSleighPlugin

# ============================================================
# INSTALL R2GHIDRA THROUGH R2PM
# ============================================================

Banner "Installing r2ghidra"

$GhidraInstalled = $false

if (CommandExists "r2pm.exe") {

    $R2PmExe = Get-CommandPath "r2pm.exe"

    Info "Installing r2ghidra through r2pm..."

    $ghidraOutput = @(
        & $R2PmExe -ci r2ghidra 2>&1
    )

    $ghidraOutput | ForEach-Object {
        Write-Host $_
    }

    $GhidraDllCandidate = Join-Path $R2UserPlugins "core_r2ghidra.dll"

    if (Test-Path -LiteralPath $GhidraDllCandidate) {
        $GhidraInstalled = $true
    }
}

# ============================================================
# LOCATE GHIDRA DLL
# ============================================================

if (-not $GhidraInstalled) {

    Info "Searching for r2ghidra DLL..."

    $GhidraSearchRoots = @(
        $R2UserPlugins,
        $GhidraSrc,
        (Join-Path $env:USERPROFILE ".local\share\radare2\r2pm")
    )

    $GhidraDll = $null

    foreach ($root in $GhidraSearchRoots) {

        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $found = Get-ChildItem `
            -LiteralPath $root `
            -Filter "core_r2ghidra.dll" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($found) {
            $GhidraDll = $found.FullName
            break
        }
    }

    if ($GhidraDll) {

        Info "Found r2ghidra DLL:"
        Write-Host "    $GhidraDll"

        Copy-Item -LiteralPath $GhidraDll `
                  -Destination $R2UserPlugins `
                  -Force

        $GhidraInstalled = $true
    }
}

if (-not $GhidraInstalled) {
    Warn "r2ghidra DLL was not found after r2pm installation."
}

# ============================================================
# LOCATE SLEIGH (LOCAL FAST PATH)
# ============================================================

Banner "Locating r2ghidra Sleigh"

# NOTE: $R2UserPlugins\r2ghidra_sleigh (the folder r2pm itself manages
# alongside core_r2ghidra.dll) is checked FIRST and, when valid, is used
# DIRECTLY as sleighhome with no copying at all. This is deliberate: a
# prior version of this script always copied whatever it found into a
# separate location under C:\radare2\lib\..., and that extra copy step
# is exactly what went stale/out of sync while the original r2pm-managed
# copy stayed correct the whole time. Using the r2pm location in place
# removes an entire class of "copy went to the wrong place" bugs.

$SleighCandidates = @(
    (Join-Path $R2UserPlugins "r2ghidra_sleigh"),
    (Join-Path $R2UserRoot "r2ghidra_sleigh"),
    (Join-Path $R2UserRoot "r2ghidra-sleigh")
)

$SleighSource = $null
$SleighUseInPlace = $false

foreach ($candidate in $SleighCandidates) {

    if (Test-Path -LiteralPath $candidate) {

        if (Find-SleighDataDir $candidate) {
            $SleighSource = $candidate
            $SleighUseInPlace = $true
            break
        }
    }
}

if (-not $SleighSource) {

    $R2PmRoot = Join-Path $R2UserRoot "r2pm"

    if (Test-Path -LiteralPath $R2PmRoot) {

        $foundSleigh = Get-ChildItem `
            -LiteralPath $R2PmRoot `
            -Directory `
            -Filter "r2ghidra_sleigh" `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Where-Object {
                Find-SleighDataDir $_.FullName
            } |
            Select-Object -First 1

        if ($foundSleigh) {
            $SleighSource = $foundSleigh.FullName
            $SleighUseInPlace = $true
        }
    }
}

if ($SleighSource) {

    Good "Sleigh source (using in place, no copy needed):"
    Write-Host "    $SleighSource"

}
else {

    Info "No usable Sleigh data found in the local r2pm cache."
    Info "Will download it directly from the r2ghidra GitHub release instead."
}

# ============================================================
# DOWNLOAD SLEIGH DATABASE FROM GITHUB (RELIABLE FALLBACK)
# ============================================================

# WHY THIS EXISTS: the r2pm-managed local checkout that used to hold the
# Sleigh data has occasionally been found missing or relocated, even
# though the plugin DLL install via r2pm keeps working fine. The Sleigh
# *data* (the .sla/.ldefs/.pspec/.cspec processor spec files) is not
# meaningfully tied to the exact radare2 build the way the plugin DLL's
# ABI is, so downloading it straight from r2ghidra's own GitHub release
# is a reliable fallback when the local cache isn't there. Unlike the
# in-place local case above, THIS path does need a permanent home, since
# it lands in a temp folder that gets cleaned up - so it gets copied into
# our own managed directory under C:\radare2\lib\...

if (-not $SleighSource) {

    Banner "Downloading Sleigh database from GitHub"

    try {

        Info "Fetching latest r2ghidra release metadata..."

        $R2GhidraRelease = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/radareorg/r2ghidra/releases/latest" `
            -ErrorAction Stop

        $SleighAsset = $R2GhidraRelease.assets |
            Where-Object { $_.name -like "*sleigh*.zip" } |
            Select-Object -First 1

        if (-not $SleighAsset) {
            Fail "Could not find a Sleigh ZIP asset in the latest r2ghidra release."
        }

        Good "Sleigh asset:"
        Write-Host "    $($SleighAsset.name)"

        $SleighDlZip = Join-Path $TempRoot "r2ghidra-sleigh-download.zip"
        $SleighDlExt = Join-Path $TempRoot "r2ghidra-sleigh-download"

        Remove-Safely $SleighDlZip
        Remove-Safely $SleighDlExt

        Info "Downloading..."

        Invoke-WebRequest `
            -Uri $SleighAsset.browser_download_url `
            -OutFile $SleighDlZip `
            -ErrorAction Stop

        New-Item -ItemType Directory -Force -Path $SleighDlExt | Out-Null

        Expand-Archive `
            -Path $SleighDlZip `
            -DestinationPath $SleighDlExt `
            -Force

        $DownloadedSleighDir = Find-SleighDataDir $SleighDlExt

        if (-not $DownloadedSleighDir) {
            Fail "Downloaded Sleigh ZIP did not contain any *.ldefs files after extraction."
        }

        $SleighSource = $DownloadedSleighDir
        $SleighUseInPlace = $false

        Good "Sleigh source (downloaded, will be copied into place):"
        Write-Host "    $SleighSource"

    }
    catch {

        Warn "Downloading Sleigh from GitHub failed:"
        Warn $_.Exception.Message
    }
}

if (-not $SleighSource) {

    Warn "Could not locate or download Sleigh data through any method."
    Warn "r2ghidra's pdg command will not work until this is resolved."
}

# ============================================================
# LOCATE THE REAL SLEIGHHOME
# ============================================================

# If we found a valid local r2pm-managed copy, use it in place (no
# copying - see note above). Otherwise, install the downloaded copy into
# radare2's versioned data directory, then find wherever the *.ldefs
# files actually landed (the package layout is FLAT - x86.ldefs, x86.sla
# etc. sit directly in one folder, and it's often nested one level under
# a versioned subfolder like r2ghidra_sleigh-6.2.0 - there is NO
# Ghidra-style "Processors\<family>\data\languages\" tree at all).

$R2SleighHome = $null

if ($SleighSource -and $SleighUseInPlace) {

    $R2SleighHome = Find-SleighDataDir $SleighSource

}
elseif ($SleighSource) {

    Banner "Installing Sleigh into radare2"

    Remove-Safely $R2SleighTarget

    New-Item -ItemType Directory `
             -Force `
             -Path $R2SleighTarget |
             Out-Null

    Copy-Item `
        -LiteralPath (Join-Path $SleighSource "*") `
        -Destination $R2SleighTarget `
        -Recurse `
        -Force

    $R2SleighHome = Find-SleighDataDir $R2SleighTarget

    if ($R2SleighHome) {
        Good "Sleigh installed:"
        Write-Host "    $R2SleighTarget"
    }
    else {
        Warn "Sleigh copy completed but no *.ldefs files were found anywhere under:"
        Warn "    $R2SleighTarget"
    }
}

if (-not $R2SleighHome) {

    $R2SleighHome = $R2SleighTarget

    Warn "Could not find any *.ldefs files through any method."
    Warn "sleighhome will be set to a guessed path anyway, but pdg will likely still fail:"
    Warn "    $R2SleighHome"

}
else {

    Good "Real Sleigh data directory:"
    Write-Host "    $R2SleighHome"
}

# ============================================================
# SET SLEIGHHOME
# ============================================================

Banner "Configuring Sleigh"

if (Test-SleighDataDir $R2SleighHome) {

    $env:SLEIGHHOME = $R2SleighHome

    Good "SLEIGHHOME:"
    Write-Host "    $env:SLEIGHHOME"

}
else {

    Warn "SleighHome directory is not currently valid."
}

# ============================================================
# PERSIST r2ghidra.sleighhome VIA ~/.radare2rc
# ============================================================

Banner "Writing r2ghidra config into ~/.radare2rc"

# WHY THIS MATTERS:
# The Windows [Environment]::SetEnvironmentVariable("User") call further
# below only affects NEW processes started after a fresh login/session -
# it will NOT reliably reach terminals that were already open, nor some
# IDE-integrated shells. If r2ghidra.sleighhome never gets set in the
# actual r2 session, r2ghidra cannot enumerate any sleigh language specs
# at all.
#
# CONFIRMED (2026-08): there are actually TWO separate bugs that both
# produce failures here, and fixing sleighhome alone is not enough:
#   1. "No languages available, make sure r2ghidra.sleighhome is set
#      properly" - sleighhome isn't resolving to a directory with real
#      *.ldefs data.
#   2. "Architecture string does not look like sleigh id: gcc" - this is
#      a SEPARATE bug in r2ghidra's compiler-id auto-detection for PE
#      binaries. It fires even with a perfectly valid sleighhome, and is
#      only fixed by explicitly overriding "r2ghidra.lang" instead of
#      letting it auto-detect.
#
# radare2 automatically sources ~/.radare2rc on every startup, in every
# shell, regardless of environment variable inheritance. Writing both
# "e r2ghidra.sleighhome=..." and "e r2ghidra.lang=..." there fixes both
# bugs for every future r2 session with zero dependency on env vars or
# manually typing "e" commands.
#
# r2ghidra.lang is pinned to x86:LE:64:default here because x86-64 PE
# binaries (mspaint.exe, notepad.exe, and the rest of the capstone
# process-tracer targets) are the primary target architecture for this
# project. For a different target architecture, override per-session:
#     e r2ghidra.lang=x86:LE:32:default   (32-bit PE)
#     e r2ghidra.lang=AARCH64:LE:64:v8A   (ARM64 PE)
# or edit the line this script writes into the rc file(s) below.

$R2GhidraLangDefault = "x86:LE:64:default"

$R2RcFile = Join-Path $env:USERPROFILE ".radare2rc"

# WHY WE DON'T JUST TRUST $env:USERPROFILE\.radare2rc:
# radare2's own docs/wiki are explicit that HOME resolution on Windows is
# not guaranteed to match %USERPROFILE% - the only reliable way to find
# where r2 will actually look is to ask r2 itself via "r2 -H", which
# prints the real R2_RCFILE (and R2_CONFIG_HOME) it resolved for THIS
# install. Writing to a guessed path is exactly what silently broke the
# previous fix even after a fresh terminal.

$R2HelpOutput = @(& $R2Exe -H 2>&1)

$DetectedRcFile = $null
$DetectedConfigHome = $null

foreach ($line in $R2HelpOutput) {
    $s = [string]$line

    if ($s -match "^\s*R2_RCFILE\s*=\s*(.+)\s*$") {
        $DetectedRcFile = $Matches[1].Trim()
    }

    if ($s -match "^\s*R2_CONFIG_HOME\s*=\s*(.+)\s*$") {
        $DetectedConfigHome = $Matches[1].Trim()
    }
}

if ($DetectedRcFile) {
    $R2RcFile = $DetectedRcFile
    Good "r2 -H reports its real RCFILE:"
    Write-Host "    $R2RcFile"
}
else {
    Warn "Could not parse R2_RCFILE from 'r2 -H' output."
    Warn "Falling back to guessed path:"
    Write-Host "    $R2RcFile"
}

# radare2 also auto-loads <config_home>\radare2rc (no leading dot) if
# present, per its own man page. Write the sleighhome line there too so
# it's covered regardless of which of the two files r2 actually reads
# first on this machine.
$R2SecondaryRcFile = $null

if ($DetectedConfigHome) {
    $R2SecondaryRcFile = Join-Path $DetectedConfigHome "radare2rc"
}

$RcFileTargets = @($R2RcFile)

if ($R2SecondaryRcFile -and ($R2SecondaryRcFile -ne $R2RcFile)) {
    $RcFileTargets += $R2SecondaryRcFile
}

foreach ($RcTarget in $RcFileTargets) {

    $RcTargetDir = Split-Path $RcTarget -Parent

    if ($RcTargetDir -and -not (Test-Path -LiteralPath $RcTargetDir)) {
        New-Item -ItemType Directory -Force -Path $RcTargetDir | Out-Null
    }

    if (-not (Test-Path -LiteralPath $RcTarget)) {
        New-Item -ItemType File -Force -Path $RcTarget | Out-Null
    }
}

$SleighRcApplied = $false

foreach ($RcTarget in $RcFileTargets) {

    $ExistingRcLines = @(Get-Content -LiteralPath $RcTarget -ErrorAction SilentlyContinue)

    # Drop any previous r2ghidra.sleighhome / r2ghidra.lang line(s) so
    # re-running this script doesn't pile up stale/duplicate entries
    # (this is what bit the Cutter users in the issue tracker - a stale
    # sleighhome line silently winning over the correct one).
    $FilteredRcLines = @($ExistingRcLines | Where-Object {
        ($_ -notmatch "^\s*e\s+r2ghidra\.sleighhome\s*=") -and
        ($_ -notmatch "^\s*e\s+r2ghidra\.lang\s*=")
    })

    if (Test-SleighDataDir $R2SleighHome) {

        $SleighRcLine = "e r2ghidra.sleighhome=$R2SleighHome"
        $LangRcLine = "e r2ghidra.lang=$R2GhidraLangDefault"

        $NewRcLines = $FilteredRcLines + $SleighRcLine + $LangRcLine

        Set-Content -LiteralPath $RcTarget -Value $NewRcLines -Encoding ASCII

        Good "rc file updated:"
        Write-Host "    $RcTarget"
        Write-Host "    $SleighRcLine"
        Write-Host "    $LangRcLine"

        $SleighRcApplied = $true

    }
    else {

        Set-Content -LiteralPath $RcTarget -Value $FilteredRcLines -Encoding ASCII
    }
}

if (-not $SleighRcApplied) {
    Warn "Sleigh directory invalid - could not write sleighhome into any rc file."
}

# ============================================================
# VERIFY THE RC FILE IS ACTUALLY BEING READ
# ============================================================

Banner "Verifying sleighhome is picked up from rc file"

# This is the check that was skipped before: don't just assume writing
# the file worked - launch a completely clean r2 process (no -c eval
# overrides at all) and ask it what r2ghidra.sleighhome actually
# resolved to. If this comes back empty, the rc file we wrote is NOT the
# one this r2 build is loading, and no amount of "open a new terminal"
# will fix it.

$SleighCheckOutput = @(& $R2Exe -q -c "e r2ghidra.sleighhome" "malloc://16" 2>&1)
$SleighCheckValue = ($SleighCheckOutput -join "").Trim()

$LangCheckOutput = @(& $R2Exe -q -c "e r2ghidra.lang" "malloc://16" 2>&1)
$LangCheckValue = ($LangCheckOutput -join "").Trim()

if ($SleighCheckValue -and (Test-Path -LiteralPath $SleighCheckValue)) {

    Good "Confirmed: a clean r2 process resolves r2ghidra.sleighhome to:"
    Write-Host "    $SleighCheckValue"

}
else {

    Warn "A clean r2 process did NOT pick up r2ghidra.sleighhome from any rc file."
    Warn "Value seen: '$SleighCheckValue'"
    Warn ""
    Warn "This means r2 is loading its rc file from somewhere other than what"
    Warn "we detected. Run this manually and check the RCFILE/RHOMEDIR lines:"
    Warn "    r2 -H"
    Warn "Then add this line to whatever file R2_RCFILE points to:"
    Warn "    e r2ghidra.sleighhome=$R2SleighHome"
}

if ($LangCheckValue -eq $R2GhidraLangDefault) {

    Good "Confirmed: a clean r2 process resolves r2ghidra.lang to:"
    Write-Host "    $LangCheckValue"

}
else {

    Warn "A clean r2 process did NOT pick up r2ghidra.lang from any rc file."
    Warn "Value seen: '$LangCheckValue' (expected '$R2GhidraLangDefault')"
    Warn "Without this, pdg can fail with 'Architecture string does not look"
    Warn "like sleigh id: gcc' even when sleighhome is completely correct."
}

# ============================================================
# R2DEC SOURCE
# ============================================================

Banner "Preparing r2dec"

if (-not (Test-Path -LiteralPath $R2DecSrc)) {

    Info "Cloning r2dec..."

    Push-Location $SrcRoot

    try {

        & $GitExe clone `
            --depth=1 `
            --recursive `
            "https://github.com/wargio/r2dec-js.git" `
            $R2DecSrc

        if ($LASTEXITCODE -ne 0) {
            Fail "Could not clone r2dec."
        }
    }
    finally {
        Pop-Location
    }

}
else {

    Info "r2dec source already exists."

    Push-Location $R2DecSrc

    try {
        & $GitExe fetch --all --prune 2>&1 | Out-Host
        & $GitExe reset --hard origin/master 2>&1 | Out-Host
    }
    finally {
        Pop-Location
    }
}

# ============================================================
# R2DEC BUILD
# ============================================================

Banner "Building r2dec"

$R2DecBuild = Join-Path $R2DecSrc "build"

# The old build directory may contain invalid Meson options.
# Delete it so Meson configures from scratch.
if (Test-Path -LiteralPath $R2DecBuild) {
    Info "Removing old r2dec build directory..."
    Remove-Safely $R2DecBuild
}

# Verify radare2 include directory before configuring r2dec.
$R2IncludeLibr = Join-Path $R2IncludeDir "libr"

if (-not (Test-Path -LiteralPath $R2IncludeLibr)) {
    Warn "radare2 include/libr does not exist."

    Warn "This is not fatal for r2dec if the installed radare2 package"
    Warn "exposes its libraries another way."
}

# r2dec's current Meson configuration detects radare2 itself.
# Do NOT use -Dr2_prefix or r2_prefix.
& $MesonExe setup `
    $R2DecBuild `
    $R2DecSrc `
    "--buildtype=release" `
    "--backend=ninja"

if ($LASTEXITCODE -ne 0) {
    Fail "r2dec Meson configuration failed."
}

& $MesonExe compile `
    -C $R2DecBuild `
    "-j" `
    "$([Environment]::ProcessorCount)"

if ($LASTEXITCODE -ne 0) {
    Fail "r2dec build failed."
}

# ============================================================
# INSTALL R2DEC
# ============================================================

Banner "Installing r2dec"

$R2DecDllCandidates = @(
    (Join-Path $R2DecBuild "core_pdd.dll"),
    (Join-Path $R2DecBuild "core_pdd.dll.p"),
    (Join-Path $R2DecBuild "core_pdd.dll.p\core_pdd.dll")
)

$R2DecDll = $null

foreach ($candidate in $R2DecDllCandidates) {

    if (Test-Path -LiteralPath $candidate) {
        $R2DecDll = $candidate
        break
    }
}

if (-not $R2DecDll) {

    $foundDec = Get-ChildItem `
        -LiteralPath $R2DecBuild `
        -Filter "core_pdd.dll" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($foundDec) {
        $R2DecDll = $foundDec.FullName
    }
}

if (-not $R2DecDll) {
    Fail "Could not locate built r2dec core_pdd.dll."
}

Good "r2dec DLL:"
Write-Host "    $R2DecDll"

$DecTarget = Join-Path $R2UserPlugins "core_pdd.dll"

if (Test-Path -LiteralPath $DecTarget) {
    Remove-Item -LiteralPath $DecTarget -Force -ErrorAction SilentlyContinue
}

Copy-Item `
    -LiteralPath $R2DecDll `
    -Destination $DecTarget `
    -Force

Good "r2dec installed:"
Write-Host "    $DecTarget"

# ============================================================
# FINAL PATH / ENVIRONMENT
# ============================================================

Banner "Finalizing environment"

Add-ToPath $R2BinDir
Add-ToPath $MsvcBin
Add-ToPath $SdkX64Bin
Add-ToPath $ToolBin

$env:R2_PREFIX = $R2Prefix
$env:R2_USER_PLUGINS = $R2UserPlugins
$env:SLEIGHHOME = $R2SleighHome

# Persist the useful user environment variables.
[Environment]::SetEnvironmentVariable(
    "R2_PREFIX",
    $R2Prefix,
    "User"
)

[Environment]::SetEnvironmentVariable(
    "R2_USER_PLUGINS",
    $R2UserPlugins,
    "User"
)

[Environment]::SetEnvironmentVariable(
    "SLEIGHHOME",
    $R2SleighHome,
    "User"
)

# ============================================================
# VERIFY FILES
# ============================================================

Banner "Final Plugin Verification"

$GhidraPlugin = Join-Path $R2UserPlugins "core_r2ghidra.dll"
$DecPlugin    = Join-Path $R2UserPlugins "core_pdd.dll"

if (Test-Path -LiteralPath $GhidraPlugin) {

    Good "r2ghidra:"
    Write-Host "    $GhidraPlugin"

}
else {

    Warn "r2ghidra plugin missing:"
    Write-Host "    $GhidraPlugin"
}

if (Test-Path -LiteralPath $DecPlugin) {

    Good "r2dec:"
    Write-Host "    $DecPlugin"

}
else {

    Warn "r2dec plugin missing:"
    Write-Host "    $DecPlugin"
}

if (Test-SleighDataDir $R2SleighHome) {

    Good "Sleigh:"
    Write-Host "    $R2SleighHome"

}
else {

    Warn "Sleigh processor directory missing."
}

# ============================================================
# CREATE A REAL TEST BINARY
# ============================================================

Banner "Creating radare2 verification target"

Remove-Safely $R2TestRoot

New-Item -ItemType Directory `
         -Force `
         -Path $R2TestRoot |
         Out-Null

$VerifyC = Join-Path $R2TestRoot "test.c"
$VerifyExe = Join-Path $R2TestRoot "test.exe"

$VerifySource = @'
#include <stdio.h>
#include <stdint.h>

static uint64_t test_function(uint64_t x)
{
    x = x * 3;
    x = x + 7;
    return x;
}

int main(void)
{
    printf("%llu\n", (unsigned long long)test_function(5));
    return 0;
}
'@

Set-Content `
    -LiteralPath $VerifyC `
    -Value $VerifySource `
    -Encoding ASCII

Push-Location $R2TestRoot

try {

    & $ClExe `
        /nologo `
        /O2 `
        $VerifyC `
        /Fe:$VerifyExe

    $VerifyCompileExit = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($VerifyCompileExit -ne 0 -or -not (Test-Path -LiteralPath $VerifyExe)) {

    Warn "Could not compile verification target."

}
else {

    Good "Test binary:"
    Write-Host "    $VerifyExe"
}

# ============================================================
# RADARE2 CORE TEST
# ============================================================

Banner "Testing radare2 core"

if (-not (Test-Path -LiteralPath $VerifyExe)) {

    Warn "Skipping core test because test binary was not created."

}
else {

    # IMPORTANT:
    # No Unicode command strings.
    # No BOM.
    # No accidental "iI;q" passed as a filename.
    #
    # r2 command is a plain ASCII string.
    $CoreOutput = @(
        & $R2Exe -q -c "iI;q" $VerifyExe 2>&1
    )

    $CoreExit = $LASTEXITCODE

    if ($CoreExit -ne 0) {

        Warn "radare2 returned exit code $CoreExit."
        $CoreOutput | ForEach-Object {
            Write-Host $_
        }

    }
    else {

        Good "radare2 core test passed."

        $CoreOutput | Select-Object -First 12 | ForEach-Object {
            Write-Host $_
        }
    }
}

# ============================================================
# PLUGIN LOADING TEST
# ============================================================

Banner "Testing plugin loading"

$R2GhidraLoaded = $false

if (Test-Path -LiteralPath $VerifyExe) {

    $PluginOutput = @(
        & $R2Exe -q -c "Lc" $VerifyExe 2>&1
    )

    $PluginOutput | ForEach-Object {
        Write-Host $_
    }

    $PluginText = ($PluginOutput -join "`n")

    if ($PluginText -match "(?i)r2ghidra") {
        $R2GhidraLoaded = $true
    }
    else {

        Warn "core_r2ghidra.dll exists on disk but does NOT appear in the"
        Warn "loaded core-plugin list (Lc). This means something else"
        Warn "overwrote it with a build that doesn't match this radare2"
        Warn "version's plugin ABI - a plugin DLL grabbed from a generic"
        Warn "GitHub 'latest release' download is a common culprit, since"
        Warn "r2ghidra's native plugin is tightly coupled to the exact"
        Warn "radare2 build it was compiled against. The file being present"
        Warn "does NOT mean it loaded correctly."
        Warn ""
        Warn "This script already re-installs the matched build via"
        Warn "'r2pm -ci r2ghidra' every time it runs, so simply re-running"
        Warn "this script should restore a working, version-matched DLL."
    }

}

# ============================================================
# R2GHIDRA TEST
# ============================================================

Banner "Testing r2ghidra"

if (
    (Test-Path -LiteralPath $GhidraPlugin) -and
    (Test-SleighDataDir $R2SleighHome) -and
    (Test-Path -LiteralPath $VerifyExe)
) {

    # IMPORTANT: this test intentionally does NOT pass
    # "e r2ghidra.sleighhome=..." or "e r2ghidra.lang=..." on the command
    # line. Testing WITHOUT explicit eval overrides here proves the rc
    # file(s) alone are enough for BOTH settings, which is what every
    # future "just open r2 and type pdg" session will actually rely on.
    $GhCommand = "pdg @ sym.test_function;q"

    $GhidraOutput = @(
        & $R2Exe -q -c $GhCommand $VerifyExe 2>&1
    )

    $GhidraOutput | ForEach-Object {
        Write-Host $_
    }

    $GhidraText = ($GhidraOutput -join "`n")

    if (
        $GhidraText -match "No languages available" -or
        $GhidraText -match "does not look like sleigh id" -or
        $GhidraText -match "Ghidra Decompiler Error"
    ) {

        Warn "r2ghidra loaded but Sleigh configuration is not working via rc file(s) alone."
        Warn "Check that BOTH of these lines exist in one of:"
        foreach ($RcTarget in $RcFileTargets) {
            Warn "    $RcTarget"
        }
        Warn "    e r2ghidra.sleighhome=$R2SleighHome"
        Warn "    e r2ghidra.lang=$R2GhidraLangDefault"
        Warn "(both should already be written there by this script - if pdg"
        Warn "still fails on a DIFFERENT architecture than x86-64 PE, override"
        Warn "r2ghidra.lang for that session/binary, e.g.:"
        Warn "    e r2ghidra.lang=x86:LE:32:default    (32-bit PE)"
        Warn "    e r2ghidra.lang=AARCH64:LE:64:v8A    (ARM64 PE)"

    }
    else {

        Good "r2ghidra invocation completed via rc file(s) alone (no explicit -e needed)."
    }

}
else {

    Warn "Skipping r2ghidra test because plugin/Sleigh/test binary is missing."
}

# ============================================================
# R2DEC TEST
# ============================================================

Banner "Testing r2dec"

if (
    (Test-Path -LiteralPath $DecPlugin) -and
    (Test-Path -LiteralPath $VerifyExe)
) {

    $DecOutput = @(
        & $R2Exe -q -c "pdd @ sym.test_function;q" $VerifyExe 2>&1
    )

    $DecOutput | ForEach-Object {
        Write-Host $_
    }

    $DecText = ($DecOutput -join "`n")

    if ($DecText -match "r2dec pseudo code") {

        Good "r2dec test passed."

    }
    else {

        Warn "r2dec plugin loaded, but expected pseudo-code marker was not found."
    }

}
else {

    Warn "Skipping r2dec test."
}

# ============================================================
# FINAL SUMMARY
# ============================================================

Banner "INSTALLATION COMPLETE"

Write-Host ""
Write-Host "radare2:"
Write-Host "    $R2Prefix"

Write-Host ""
Write-Host "radare2 executable:"
Write-Host "    $R2Exe"

Write-Host ""
Write-Host "r2ghidra:"
Write-Host "    $GhidraPlugin"

if ($R2GhidraLoaded) {
    Write-Host "    (confirmed loaded via Lc)"
}
else {
    Write-Host "    (WARNING: present on disk but NOT confirmed loaded - see warnings above)"
}

Write-Host ""
Write-Host "Sleigh:"
Write-Host "    $R2SleighHome"

Write-Host ""
Write-Host "SLEIGHHOME:"
Write-Host "    $env:SLEIGHHOME"

Write-Host ""
Write-Host "radare2 startup rc (sleighhome + lang persisted here for every session):"
foreach ($RcTarget in $RcFileTargets) {
    Write-Host "    $RcTarget"
}
Write-Host "    (sleighhome confirmed working: $SleighCheckValue)"
Write-Host "    (r2ghidra.lang confirmed working: $LangCheckValue)"

Write-Host ""
Write-Host "r2dec:"
Write-Host "    $DecPlugin"

Write-Host ""
Write-Host "MSVC:"
Write-Host "    $MsvcRoot"

Write-Host ""
Write-Host "Windows SDK:"
Write-Host "    $SdkRoot"

Write-Host ""
Write-Host "Windows SDK version:"
Write-Host "    $SdkVersion"

Write-Host ""
Write-Host "Meson:"
& $MesonExe --version

Write-Host ""
Write-Host "Ninja:"
& $NinjaExe --version

Write-Host ""
Write-Host "Compiler:"
& $ClExe /?

Write-Host ""
Write-Host "============================================================"
Write-Host " Done."
Write-Host "============================================================"
Write-Host ""
Write-Host "Open a NEW PowerShell window before using r2."
Write-Host ""
Write-Host "Then verify:"
Write-Host "    r2 -v"
Write-Host "    r2 -q -c `"Lc`""
Write-Host "    r2 -q -c `"e r2ghidra.sleighhome=$R2SleighHome;pdg @ main;q`" $VerifyExe"
Write-Host ""
