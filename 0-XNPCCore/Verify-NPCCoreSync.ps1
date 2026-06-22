# Compare NPCCore repo vs deployed Mods folder for drift.
# Prints differences in file paths and sizes.
# Exits 1 if out of sync, 0 if clean.
# Usage: powershell -NoProfile -File Verify-NPCCoreSync.ps1

$ErrorActionPreference = "Stop"

# --- Configuration ---
$RepoPath    = Split-Path -Parent $MyInvocation.MyCommand.Path
$GamePath    = "C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die"
$ModsPath    = Join-Path $GamePath "Mods\0-XNPCCore"

if (-not (Test-Path $ModsPath)) {
    Write-Host ""
    Write-Host "ERROR: Deployed folder not found at $ModsPath" -ForegroundColor Red
    Write-Host "Run Deploy-NPCCore.ps1 first." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Gather files (exclude .git)
$repoFiles = Get-ChildItem -Path $RepoPath -Recurse -File | Where-Object {
    $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.Extension -ne '.ps1'
} | ForEach-Object {
    $rel = $_.FullName.Substring($RepoPath.Length).TrimStart('\')
    [PSCustomObject]@{
        RelPath = $rel
        Length  = $_.Length
    }
}

$deployFiles = Get-ChildItem -Path $ModsPath -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($ModsPath.Length).TrimStart('\')
    [PSCustomObject]@{
        RelPath = $rel
        Length  = $_.Length
    }
}

$repoLookup  = @{$true = @{} }; $repoLookup[$true] = @{}
foreach ($f in $repoFiles) { $repoLookup[$true][$f.RelPath] = $f.Length }

$deployLookup = @{$true = @{} }; $deployLookup[$true] = @{}
foreach ($f in $deployFiles) { $deployLookup[$true][$f.RelPath] = $f.Length }

$drift = 0

# Files missing from deploy (in repo but not deployed)
foreach ($path in $repoLookup[$true].Keys) {
    if (-not $deployLookup[$true].ContainsKey($path)) {
        Write-Host "MISSING in deploy: $path" -ForegroundColor Red
        $drift++
    }
}

# Files extra in deploy (deployed but not in repo)
foreach ($path in $deployLookup[$true].Keys) {
    if (-not $repoLookup[$true].ContainsKey($path)) {
        Write-Host "EXTRA in deploy:   $path" -ForegroundColor Yellow
        $drift++
    }
}

# Size mismatches
foreach ($path in $repoLookup[$true].Keys) {
    if ($deployLookup[$true].ContainsKey($path)) {
        $rLen = $repoLookup[$true][$path]
        $dLen = $deployLookup[$true][$path]
        if ($rLen -ne $dLen) {
            Write-Host "SIZE MISMATCH:   $path (repo=$rLen, deploy=$dLen)" -ForegroundColor Red
            $drift++
        }
    }
}

Write-Host ""
if ($drift -gt 0) {
    Write-Host "DRIFT DETECTED: $drift difference(s). Run Deploy-NPCCore.ps1 to sync." -ForegroundColor Red
    Write-Host ""
    exit 1
} else {
    $total = $repoFiles.Count
    Write-Host "SYNC OK: $total files match between repo and deploy." -ForegroundColor Green
    Write-Host ""
    exit 0
}
