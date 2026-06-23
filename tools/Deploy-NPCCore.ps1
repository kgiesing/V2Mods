# Deploy 0-XNPCCore from repo to live game Mods folder.
# Aborts if 7DaysToDie.exe is running.
# Runs shared XML validator before copy.
# Uses robocopy /MIR (safe - NPCCore writes no runtime data).
# Usage: powershell -NoProfile -File Deploy-NPCCore.ps1

$ErrorActionPreference = "Stop"

# --- Configuration ---
$RepoPath    = (Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path
$GamePath    = "C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die"
$ModsPath    = Join-Path $GamePath "Mods\0-XNPCCore"
$Validator   = "D:\GitHub\NPCVoiceControlMod\tools\Validate-ModXml.ps1"

# --- (a) Abort if game running ---
if (Get-Process -Name "7DaysToDie" -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "ABORT: 7DaysToDie.exe is running. Close the game before deploying." -ForegroundColor Red
    Write-Host ""
    exit 1
}

# --- (b) Run shared XML validator ---
Write-Host "=== Validating NPCCore Config XML ===" -ForegroundColor Cyan
if (-not (Test-Path $Validator)) {
    Write-Host "ABORT: Shared validator not found at $Validator" -ForegroundColor Red
    exit 1
}

$validatorExit = 0
& powershell -NoProfile -ExecutionPolicy Bypass -File $Validator -ConfigPath "$RepoPath\Config"
$validatorExit = $LASTEXITCODE

if ($validatorExit -ne 0) {
    Write-Host ""
    Write-Host "ABORT: XML validation failed. Fix errors before deploying." -ForegroundColor Red
    Write-Host ""
    exit 1
}

# --- (c) robocopy /MIR /XD .git ---
Write-Host ""
Write-Host "=== Deploying NPCCore to $ModsPath ===" -ForegroundColor Cyan
& robocopy $RepoPath $ModsPath /MIR /XD .git /XF *.ps1

if ($LASTEXITCODE -ge 8) {
    Write-Host ""
    Write-Host "ERROR: robocopy failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "NPCCore deploy complete." -ForegroundColor Green
Write-Host ""
