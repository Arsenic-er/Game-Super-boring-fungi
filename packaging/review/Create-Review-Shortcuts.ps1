[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($PSScriptRoot)
$exe = Join-Path $root 'FungiMicroculture.exe'
$pck = Join-Path $root 'FungiMicroculture.pck'
$manifestPath = Join-Path $root 'build-info.json'
foreach ($path in @($exe, $pck, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing required review file: $path" }
    if ((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing a linked review file: $path"
    }
}
$info = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($name in @('FungiMicroculture.exe', 'FungiMicroculture.pck')) {
    $expected = $info.files.PSObject.Properties[$name].Value.sha256
    if ((Get-FileHash -LiteralPath (Join-Path $root $name) -Algorithm SHA256).Hash -ine $expected) {
        throw "Review file hash mismatch: $name"
    }
}
$expectedIds = @('first_supply', 'remote_pantry', 'first_contact', 'substrate_race', 'lost_network', 'two_fronts', 'toxic_frontier', 'boundary_counterattack', 'stable_colony')
if (@($info.missions).Count -ne 9) { throw 'The review manifest must contain exactly nine missions.' }
$shell = New-Object -ComObject WScript.Shell
$created = @()
try {
    for ($i = 0; $i -lt $expectedIds.Count; $i++) {
        $mission = $info.missions[$i]
        if ($mission.id -cne $expectedIds[$i]) { throw 'Review mission IDs or ordering mismatch.' }
        $label = ('{0:D2} {1}.lnk' -f ($i + 1), $mission.title_zh)
        if ($label.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { throw 'Invalid shortcut title.' }
        $path = Join-Path $root $label
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path -Force
            if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Unsafe existing shortcut: $path" }
        }
        $shortcut = $shell.CreateShortcut($path)
        $shortcut.TargetPath = $exe
        $shortcut.Arguments = '--scene res://scenes/ReviewSlice.tscn -- --review-mission=' + $mission.id + ' --review-lang=zh_CN'
        $shortcut.WorkingDirectory = $root
        $shortcut.IconLocation = $exe + ',0'
        $shortcut.Description = $mission.title_zh + ' | ' + $info.build_id
        $shortcut.WindowStyle = 1
        $shortcut.Save()
        $verify = $shell.CreateShortcut($path)
        if ($verify.TargetPath -ine $exe -or $verify.Arguments -cne $shortcut.Arguments -or $verify.WorkingDirectory -ine $root) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($verify)
            throw "Shortcut verification failed: $path"
        }
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($verify)
        $created += $label
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut)
    }
} finally {
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
}
Write-Output ('REVIEW_SHORTCUTS_OK: ' + $created.Count + ' entries')
Write-Output ('SOURCE_COMMIT: ' + $info.source_commit)
Write-Output ('BUILD_ID: ' + $info.build_id)
Write-Output 'Shortcuts use this folder. Run this script again after moving the folder.'
