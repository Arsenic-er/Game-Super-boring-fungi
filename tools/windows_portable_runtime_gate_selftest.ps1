[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$gatePath = Join-Path $PSScriptRoot "windows_portable_runtime_smoke.ps1"
$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$workDir = [System.IO.Path]::GetFullPath(
    (Join-Path $tempBase ("fungi-runtime-gate-selftest-" + [guid]::NewGuid().ToString("N")))
)

if (-not $workDir.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to create self-test files outside the Windows temporary directory"
}

New-Item -ItemType Directory -Path $workDir | Out-Null

try {
    if (-not (Test-Path -LiteralPath $gatePath -PathType Leaf)) {
        throw "Runtime gate is missing: $gatePath"
    }

    $stageDir = Join-Path $workDir "valid"
    New-Item -ItemType Directory -Path $stageDir | Out-Null

    $source = @"
using System;
public static class FungiRuntimeGateFixture
{
    public static int Main(string[] args)
    {
        return 0;
    }
}
"@

    $sourcePath = Join-Path $stageDir "fixture.cs"
    $fixtureExe = Join-Path $stageDir "FungiMicroculture.exe"
    $csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (-not (Test-Path -LiteralPath $csc -PathType Leaf)) {
        throw "C# compiler is unavailable: $csc"
    }
    Set-Content -LiteralPath $sourcePath -Value $source -NoNewline
    & $csc /nologo /target:exe "/out:$fixtureExe" $sourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to compile the runtime-gate fixture executable"
    }
    Remove-Item -LiteralPath $sourcePath -Force
    Set-Content -LiteralPath (Join-Path $stageDir "FungiMicroculture.pck") `
        -Value "fixture game data" -NoNewline
    Set-Content -LiteralPath (Join-Path $stageDir "README-FIRST.txt") `
        -Value "keep exe and pck together" -NoNewline

    $validArchive = Join-Path $workDir "valid.zip"
    Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $validArchive
    & $gatePath -ArchivePath $validArchive -TimeoutSeconds 10 -QuitAfterFrames 2

    $invalidDir = Join-Path $workDir "invalid"
    New-Item -ItemType Directory -Path $invalidDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $stageDir "FungiMicroculture.exe") -Destination $invalidDir
    Copy-Item -LiteralPath (Join-Path $stageDir "README-FIRST.txt") -Destination $invalidDir
    $invalidArchive = Join-Path $workDir "missing-pck.zip"
    Compress-Archive -Path (Join-Path $invalidDir "*") -DestinationPath $invalidArchive

    $rejected = $false
    try {
        & $gatePath -ArchivePath $invalidArchive -TimeoutSeconds 10 -QuitAfterFrames 2
    }
    catch {
        $rejected = $true
    }
    if (-not $rejected) {
        throw "Runtime gate accepted an archive without FungiMicroculture.pck"
    }

    Write-Output "WINDOWS_PORTABLE_RUNTIME_GATE_SELFTEST_OK"
}
finally {
    if (
        (Test-Path -LiteralPath $workDir) -and
        $workDir.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        Remove-Item -LiteralPath $workDir -Recurse -Force
    }
}
