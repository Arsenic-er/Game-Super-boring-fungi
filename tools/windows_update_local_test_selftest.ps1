[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot 'windows_update_local_test.ps1'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$work = Join-Path $tempRoot ('fungi-local-update-selftest-' + [guid]::NewGuid().ToString('N'))
if (-not ([IO.Path]::GetFullPath($work)).StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe self-test path' }
New-Item -ItemType Directory -Path $work | Out-Null
$holding = $null

function Expect-Rejection([scriptblock]$Action, [string]$Reason) {
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw "Expected rejection: $Reason" }
}

try {
    $source = Join-Path $work 'source'
    $target = Join-Path $work 'current'
    New-Item -ItemType Directory -Path $source | Out-Null
    $fixtureSource = @'
using System;
public static class FungiLocalUpdateFixture {
    public static int Main(string[] args) {
        if (Array.IndexOf(args, "--hold") >= 0) System.Threading.Thread.Sleep(30000);
        return 0;
    }
}
'@
    $csPath = Join-Path $work 'fixture.cs'
    [IO.File]::WriteAllText($csPath, $fixtureSource)
    $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    & $csc /nologo /target:exe ('/out:' + (Join-Path $source 'FungiMicroculture.exe')) $csPath
    if ($LASTEXITCODE -ne 0) { throw 'Fixture compiler failed' }
    [IO.File]::WriteAllText((Join-Path $source 'README-FIRST.txt'), 'test fixture')
    foreach ($version in @(1, 2)) {
        [IO.File]::WriteAllText((Join-Path $source 'FungiMicroculture.pck'), "fixture-version-$version")
        $zip = Join-Path $work 'download.zip'
        Compress-Archive -Path (Join-Path $source '*') -DestinationPath $zip
        $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        & $installer -ArchivePath $zip -Destination $target -ExpectedSha256 $hash -SourceCommit ('abcdef' + $version) -RemoveArchive
        if (Test-Path -LiteralPath $zip) { throw 'Consumed download archive was retained' }
        if ((Get-Content -LiteralPath (Join-Path $target 'FungiMicroculture.pck') -Raw) -ne "fixture-version-$version") { throw 'Latest data was not installed' }
        $manifest = Get-Content -LiteralPath (Join-Path $target 'build-info.json') -Raw | ConvertFrom-Json
        if ($manifest.source_commit -ne ('abcdef' + $version)) { throw 'Manifest was not replaced' }
        if (@(Get-ChildItem -LiteralPath $work -Directory -Force | Where-Object Name -like '.fungi-update-*').Count -ne 0) { throw 'An obsolete stage or backup was retained' }
        if ($version -eq 1) { [IO.File]::WriteAllText((Join-Path $target 'keep-user-note.txt'), 'preserve me') }
    }
    if ((Get-Content -LiteralPath (Join-Path $target 'keep-user-note.txt') -Raw) -ne 'preserve me') { throw 'An unrelated user file was altered' }
    $before = (Get-FileHash -LiteralPath (Join-Path $target 'FungiMicroculture.pck')).Hash
    $zip = Join-Path $work 'rejected.zip'
    Compress-Archive -Path (Join-Path $source '*') -DestinationPath $zip
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    Expect-Rejection { & $installer -ArchivePath $zip -Destination $target -ExpectedSha256 ('0' * 64) -SourceCommit abcdef3 } 'incorrect hash'
    Expect-Rejection { & $installer -ArchivePath $zip -Destination ([IO.Path]::GetPathRoot($target)) -ExpectedSha256 $hash -SourceCommit abcdef3 } 'drive root'
    $holding = Start-Process -FilePath (Join-Path $target 'FungiMicroculture.exe') -ArgumentList '--hold' -WindowStyle Hidden -PassThru
    Expect-Rejection { & $installer -ArchivePath $zip -Destination $target -ExpectedSha256 $hash -SourceCommit abcdef3 } 'running installed game'
    if ($holding.HasExited) { throw 'Updater stopped the running game' }
    Stop-Process -Id $holding.Id -Force
    $holding.WaitForExit()
    $holding = $null
    # Lock the old PCK so replacement fails after the EXE has already moved.
    # The updater must restore that EXE and leave no backup directory behind.
    $oldExeHash = (Get-FileHash -LiteralPath (Join-Path $target 'FungiMicroculture.exe')).Hash
    $lockedPck = [IO.File]::Open((Join-Path $target 'FungiMicroculture.pck'), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        Expect-Rejection { & $installer -ArchivePath $zip -Destination $target -ExpectedSha256 $hash -SourceCommit abcdef3 } 'locked file during replacement'
    }
    finally { $lockedPck.Dispose() }
    if ((Get-FileHash -LiteralPath (Join-Path $target 'FungiMicroculture.exe')).Hash -ne $oldExeHash) { throw 'Partial update did not restore the old EXE' }
    if (@(Get-ChildItem -LiteralPath $work -Directory -Force | Where-Object Name -like '.fungi-update-*').Count -ne 0) { throw 'Successful rollback left a duplicate build' }
    $invalid = Join-Path $work 'missing-pck.zip'
    Compress-Archive -LiteralPath (Join-Path $source 'FungiMicroculture.exe'),(Join-Path $source 'README-FIRST.txt') -DestinationPath $invalid
    $invalidHash = (Get-FileHash -LiteralPath $invalid -Algorithm SHA256).Hash
    Expect-Rejection { & $installer -ArchivePath $invalid -Destination $target -ExpectedSha256 $invalidHash -SourceCommit abcdef3 } 'missing resource pack'
    if ((Get-FileHash -LiteralPath (Join-Path $target 'FungiMicroculture.pck')).Hash -ne $before) { throw 'Rejected update modified the installed build' }
    Write-Output 'FUNGI_LOCAL_UPDATE_SELFTEST_OK replacements=2 old_archives=0 backups=0 user_files=preserved rollback=passed rejects=hash,root,running,missing-pck'
}
finally {
    if ($null -ne $holding -and -not $holding.HasExited) { Stop-Process -Id $holding.Id -Force }
    if (([IO.Path]::GetFullPath($work)).StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $work)) {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
}
