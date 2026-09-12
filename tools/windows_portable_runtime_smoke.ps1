[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,

    [ValidateRange(5, 600)]
    [int]$TimeoutSeconds = 90,

    [ValidateRange(1, 600)]
    [int]$QuitAfterFrames = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$resolvedArchive = (Resolve-Path -LiteralPath $ArchivePath -ErrorAction Stop).ProviderPath
$expectedEntries = @(
    "FungiMicroculture.exe",
    "FungiMicroculture.pck",
    "README-FIRST.txt"
) | Sort-Object

$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$workDir = [System.IO.Path]::GetFullPath(
    (Join-Path $tempBase ("fungi-windows-runtime-" + [guid]::NewGuid().ToString("N")))
)
if (-not $workDir.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to extract outside the Windows temporary directory"
}

$process = $null
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
New-Item -ItemType Directory -Path $workDir | Out-Null

try {
    # Godot user:// follows APPDATA, not the extracted working directory.
    # A packaging test must not load or initialize the player's settings/saves.
    $env:APPDATA = Join-Path $workDir 'test-appdata'
    $env:LOCALAPPDATA = Join-Path $workDir 'test-localappdata'
    New-Item -ItemType Directory -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedArchive)
    try {
        $entries = @($archive.Entries)
        $entryNames = @($entries | ForEach-Object { $_.FullName } | Sort-Object)

        if ($entryNames.Count -ne $expectedEntries.Count) {
            throw "Unexpected ZIP entries: $($entryNames -join ', ')"
        }
        for ($index = 0; $index -lt $expectedEntries.Count; $index++) {
            if ($entryNames[$index] -cne $expectedEntries[$index]) {
                throw "Unexpected ZIP entries: $($entryNames -join ', ')"
            }
        }

        foreach ($entry in $entries) {
            if ($entry.Length -le 0) {
                throw "Empty ZIP entry: $($entry.FullName)"
            }
            $entryStream = $entry.Open()
            try {
                $entryStream.CopyTo([System.IO.Stream]::Null)
            }
            finally {
                $entryStream.Dispose()
            }
        }
    }
    finally {
        $archive.Dispose()
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($resolvedArchive, $workDir)

    $executable = Join-Path $workDir "FungiMicroculture.exe"
    $resourcePack = Join-Path $workDir "FungiMicroculture.pck"
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "Extracted executable is missing"
    }
    if (-not (Test-Path -LiteralPath $resourcePack -PathType Leaf)) {
        throw "Extracted PCK is missing"
    }

    $stdoutPath = Join-Path $workDir "runtime-stdout.log"
    $stderrPath = Join-Path $workDir "runtime-stderr.log"
    $arguments = @(
        "--headless",
        "--quit-after",
        $QuitAfterFrames.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    )

    $process = Start-Process -FilePath $executable -ArgumentList $arguments `
        -WorkingDirectory $workDir -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "Game did not exit within $TimeoutSeconds seconds"
    }
    $process.WaitForExit()

    $stdout = if (Test-Path -LiteralPath $stdoutPath) {
        Get-Content -LiteralPath $stdoutPath -Raw
    } else {
        ""
    }
    $stderr = if (Test-Path -LiteralPath $stderrPath) {
        Get-Content -LiteralPath $stderrPath -Raw
    } else {
        ""
    }
    $combinedOutput = $stdout + [Environment]::NewLine + $stderr

    if ($process.ExitCode -ne 0) {
        throw "Game exited with code $($process.ExitCode). Output:`n$combinedOutput"
    }
    if ($combinedOutput -match "(?im)^\s*(SCRIPT ERROR:|FATAL:|CRASH:)") {
        throw "Fatal Godot output detected:`n$combinedOutput"
    }

    Write-Output (
        "WINDOWS_PORTABLE_RUNTIME_OK: extracted EXE loaded its adjacent PCK " +
        "and exited after $QuitAfterFrames frames"
    )
}
finally {
    $env:APPDATA = $originalAppData
    $env:LOCALAPPDATA = $originalLocalAppData
    if ($null -ne $process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    if (
        (Test-Path -LiteralPath $workDir) -and
        $workDir.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        Remove-Item -LiteralPath $workDir -Recurse -Force
    }
}
