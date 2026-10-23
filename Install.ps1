param(
    [string]$SkillsRoot,
    [string]$ArtifactRoot,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Test-Package.ps1') | Write-Output
if (!$SkillsRoot) {
    $codexBase = $env:CODEX_HOME
    if (!$codexBase) { $codexBase = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
    $SkillsRoot = Join-Path $codexBase 'skills'
}
$SkillsRoot = [IO.Path]::GetFullPath($SkillsRoot)
if ($SkillsRoot -eq [IO.Path]::GetPathRoot($SkillsRoot)) { throw 'SkillsRoot cannot be a filesystem root.' }
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'skills'))
if ($SkillsRoot.Equals($sourceRoot, [StringComparison]::OrdinalIgnoreCase) -or $SkillsRoot.StartsWith($sourceRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Installation target cannot be inside package skills.' }
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$settings = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config.example.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$oldSettings = Join-Path $SkillsRoot 'max-mode-cn/settings.json'
if (Test-Path -LiteralPath $oldSettings) { $settings = Get-Content -LiteralPath $oldSettings -Raw -Encoding UTF8 | ConvertFrom-Json }
if ($settings.schema_version -ne 1 -or $settings.language -ne 'zh-CN' -or $settings.project_knowledge -ne 'optional-explicit') { throw 'Existing settings are incompatible. Correct settings before installing.' }
if ($PSBoundParameters.ContainsKey('ArtifactRoot')) {
    if (!$ArtifactRoot -or ![IO.Path]::IsPathRooted($ArtifactRoot)) { throw 'ArtifactRoot must be an absolute path.' }
    $settings.artifact_root = [IO.Path]::GetFullPath($ArtifactRoot)
}
if (!$settings.artifact_root) {
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if (!$documents) { $documents = [Environment]::GetFolderPath('UserProfile') }
    $settings.artifact_root = Join-Path $documents 'CodexPlans'
}
if (![IO.Path]::IsPathRooted($settings.artifact_root)) { throw 'Configured artifact_root must be absolute.' }
$conflicts = @($manifest.skills | Where-Object { Test-Path -LiteralPath (Join-Path $SkillsRoot $_) })
Write-Output "Skills root: $SkillsRoot"
Write-Output "Artifact root: $($settings.artifact_root)"
Write-Output "Existing skills to back up: $($conflicts -join ', ')"
if ($CheckOnly) { Write-Output 'CHECK ONLY: no files changed.'; return }
$batch = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$backupRoot = Join-Path (Split-Path $SkillsRoot -Parent) "super-mode-backups/$batch"
foreach ($name in $manifest.skills) {
    $target = Join-Path $SkillsRoot $name
    if (Test-Path -LiteralPath $target) {
        $item = Get-Item -LiteralPath $target -Force
        if (!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Target is not a regular skill directory: $target" }
        $links = @(Get-ChildItem -LiteralPath $target -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
        if ($links.Count) { throw "Target contains linked files/directories: $target" }
    }
}
# Finish every backup before replacing any installed skill.
if ($conflicts.Count) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    foreach ($name in $conflicts) { Copy-Item -LiteralPath (Join-Path $SkillsRoot $name) -Destination (Join-Path $backupRoot $name) -Recurse -Force }
    Write-Output "Backup: $backupRoot"
}
$changed = @()
try {
    New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
    foreach ($name in $manifest.skills) {
        $target = Join-Path $SkillsRoot $name
        $changed += $name
        # Targets are the six manifest skill names resolved under SkillsRoot.
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        Copy-Item -LiteralPath (Join-Path $sourceRoot $name) -Destination $target -Recurse -Force
    }
    $json = $settings | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText((Join-Path $SkillsRoot 'max-mode-cn/settings.json'), $json, (New-Object Text.UTF8Encoding($false)))
    & (Join-Path $PSScriptRoot 'Test-Package.ps1') -InstalledRoot $SkillsRoot | Write-Output
} catch {
    $originalError = $_
    $rollbackErrors = @()
    foreach ($name in $changed) {
        try {
            $target = Join-Path $SkillsRoot $name
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            if ($conflicts -contains $name) { Copy-Item -LiteralPath (Join-Path $backupRoot $name) -Destination $target -Recurse -Force }
        } catch { $rollbackErrors += $_.Exception.Message }
    }
    if ($rollbackErrors.Count) { Write-Warning "Rollback incomplete. Recover from $backupRoot. $($rollbackErrors -join '; ')" }
    else { Write-Output 'Rollback completed; previous skill contents restored.' }
    throw $originalError
}
Write-Output 'Installation complete. Restart Codex or open a new chat; invoke $max-mode-cn.'
