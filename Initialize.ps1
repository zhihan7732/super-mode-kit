param(
    [Parameter(Mandatory=$true)][string]$SettingsPath,
    [switch]$Reconfigure,
    [switch]$NonInteractive
)
$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath $SettingsPath -PathType Leaf)) { throw "Settings file not found: $SettingsPath" }
$settings = Get-Content -LiteralPath $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($settings.schema_version -ne 2) { throw 'Unsupported settings schema.' }
$documents = [Environment]::GetFolderPath('MyDocuments')
if (!$documents) { $documents = [Environment]::GetFolderPath('UserProfile') }
$defaultSpace = Join-Path $documents 'CodexSpaces'
if (!$settings.space_root) { $settings.space_root = $defaultSpace }
if (!$settings.artifact_root) { $settings.artifact_root = Join-Path $settings.space_root 'plans' }
if ($NonInteractive) {
    $settings.initialized_at = (Get-Date).ToUniversalTime().ToString('o')
    New-Item -ItemType Directory -Path $settings.space_root -Force | Out-Null
    New-Item -ItemType Directory -Path $settings.artifact_root -Force | Out-Null
    [IO.File]::WriteAllText($SettingsPath, ($settings | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))
    return
}
Write-Host ''
Write-Host 'Super Mode first-install initialization' -ForegroundColor Cyan
Write-Host 'These settings affect local paths only. No content is uploaded and telemetry stays disabled.' -ForegroundColor DarkGray
Write-Host ''
if ($Reconfigure -or !$settings.initialized_at) {
    $answer = Read-Host "Space storage path [$($settings.space_root)]"
    if ($answer) { $settings.space_root = [IO.Path]::GetFullPath($answer) }
    $answer = Read-Host "Spec and plan path [$($settings.artifact_root)]"
    if ($answer) { $settings.artifact_root = [IO.Path]::GetFullPath($answer) }
    $answer = Read-Host 'Create project folders automatically (Y/n)'
    if ($answer -match '^[nN]') { $settings.create_project_folders = $false } else { $settings.create_project_folders = $true }
    Write-Host ''
    Write-Host "Space:    $($settings.space_root)"
    Write-Host "Plan artifacts: $($settings.artifact_root)"
    Write-Host "Create folders: $($settings.create_project_folders)"
    $confirm = Read-Host 'Save these settings (Y/n)'
    if ($confirm -match '^[nN]') { throw 'Initialization cancelled. Run Initialize.ps1 again to configure.' }
}
New-Item -ItemType Directory -Path $settings.space_root -Force | Out-Null
New-Item -ItemType Directory -Path $settings.artifact_root -Force | Out-Null
$settings.initialized_at = (Get-Date).ToUniversalTime().ToString('o')
[IO.File]::WriteAllText($SettingsPath, ($settings | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))
Write-Host 'Initialization complete. Use -Reconfigure to change settings.' -ForegroundColor Green
