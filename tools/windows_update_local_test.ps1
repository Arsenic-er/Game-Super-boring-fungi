[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ArchivePath,
    [Parameter(Mandatory = $true)] [string]$Destination,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{64}$')] [string]$ExpectedSha256,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{7,40}$')] [string]$SourceCommit,
    [switch]$RemoveArchive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Assert-OwnedChild([string]$Path, [string]$Parent) {
    $full = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Parent).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a path outside the update parent: $full"
    }
    if (Test-Path -LiteralPath $full) {
        if ((Get-Item -LiteralPath $full -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to update through a link or junction: $full"
        }
    }
}

$archive = (Resolve-Path -LiteralPath $ArchivePath).ProviderPath
$target = [IO.Path]::GetFullPath($Destination).TrimEnd('\', '/')
$parent = [IO.Path]::GetDirectoryName($target)
if ([string]::IsNullOrWhiteSpace($parent) -or $target -eq [IO.Path]::GetPathRoot($target).TrimEnd('\', '/')) {
    throw 'The install destination must be a dedicated folder, not a drive root.'
}
Assert-OwnedChild $target $parent
if ((Test-Path -LiteralPath $target) -and -not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "The install destination is not a directory: $target"
}
$actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
if ($actualHash -ine $ExpectedSha256) {
    throw "Archive SHA-256 mismatch; the existing test version has not been changed."
}

$managedNames = @('FungiMicroculture.exe', 'FungiMicroculture.pck', 'README-FIRST.txt', 'build-info.json')
$exePath = Join-Path $target 'FungiMicroculture.exe'
$running = @(Get-CimInstance Win32_Process -Filter "Name = 'FungiMicroculture.exe'" | Where-Object {
    $_.ExecutablePath -and [string]::Equals($_.ExecutablePath, $exePath, [StringComparison]::OrdinalIgnoreCase)
})
if ($running.Count -gt 0) {
    throw 'Close the current Fungi test game before updating. No process was stopped and no files were replaced.'
}
foreach ($name in $managedNames) {
    $path = Join-Path $target $name
    if ([string]::Equals($archive, $path, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The download archive must not occupy an installed game filename.'
    }
    Assert-OwnedChild $path $target
    if ((Test-Path -LiteralPath $path) -and -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "A managed filename is occupied by a directory: $path"
    }
}

# Validate the exact ZIP layout and start the new EXE/PCK in a disposable folder
# before moving any file from the last working test version.
& (Join-Path $PSScriptRoot 'windows_portable_runtime_smoke.ps1') -ArchivePath $archive

New-Item -ItemType Directory -Force -Path $parent | Out-Null
$suffix = [guid]::NewGuid().ToString('N')
$stage = Join-Path $parent ('.fungi-update-stage-' + $suffix)
$backup = Join-Path $parent ('.fungi-update-backup-' + $suffix)
Assert-OwnedChild $stage $parent
Assert-OwnedChild $backup $parent
$installed = [Collections.Generic.List[string]]::new()
$saved = [Collections.Generic.List[string]]::new()
$committed = $false
$rollbackComplete = $false

try {
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $stage)
    $manifest = [ordered]@{
        source_commit = $SourceCommit
        archive_sha256 = $actualHash.ToLowerInvariant()
        installed_at_utc = [DateTime]::UtcNow.ToString('o')
        layout = 'exe-and-adjacent-pck'
    } | ConvertTo-Json
    [IO.File]::WriteAllText((Join-Path $stage 'build-info.json'), $manifest, [Text.UTF8Encoding]::new($false))
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    New-Item -ItemType Directory -Path $backup | Out-Null
    foreach ($name in $managedNames) {
        $oldPath = Join-Path $target $name
        if (Test-Path -LiteralPath $oldPath -PathType Leaf) {
            Move-Item -LiteralPath $oldPath -Destination (Join-Path $backup $name)
            $saved.Add($name)
        }
        Move-Item -LiteralPath (Join-Path $stage $name) -Destination $oldPath
        $installed.Add($name)
    }
    $committed = $true
}
catch {
    $failure = $_
    try {
        foreach ($name in $installed) {
            Remove-Item -LiteralPath (Join-Path $target $name) -Force
        }
        foreach ($name in $saved) {
            Move-Item -LiteralPath (Join-Path $backup $name) -Destination (Join-Path $target $name)
        }
        $rollbackComplete = $true
    }
    catch {
        throw "Update failed and rollback needs manual recovery. Preserve backup at $backup. Cause: $failure; rollback: $_"
    }
    throw $failure
}
finally {
    foreach ($temporary in @($stage, $backup)) {
        if ($temporary -eq $backup -and -not ($committed -or $rollbackComplete)) { continue }
        Assert-OwnedChild $temporary $parent
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Recurse -Force
        }
    }
}

if ($RemoveArchive) {
    Remove-Item -LiteralPath $archive -Force
}
Write-Output "FUNGI_LOCAL_TEST_UPDATED: $exePath"
Write-Output "SOURCE_COMMIT: $SourceCommit"
Write-Output 'Only the current managed build remains; unrelated files and application-data saves were not removed.'
