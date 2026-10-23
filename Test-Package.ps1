param([string]$InstalledRoot)
$ErrorActionPreference = 'Stop'
$kitRoot = $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $kitRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedNames = @('max-mode-cn','pc-control-max-mode','speckit','speckit-superpowers-bridge','superpowers','gstack')
if (($manifest.skills -join ',') -ne ($expectedNames -join ',')) { throw 'Invalid skill inventory.' }
$knownPaths = @()
foreach ($entry in $manifest.files) {
    $relative = [string]$entry.path
    if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)' -or $relative -match ':') { throw "Unsafe manifest path: $relative" }
    if ($knownPaths -contains $relative) { throw "Duplicate manifest entry: $relative" }
    $knownPaths += $relative
    $file = Join-Path $kitRoot $relative
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $relative" }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Hash mismatch: $relative" }
}
$actualPaths = @(Get-ChildItem -LiteralPath $kitRoot -Recurse -File | Where-Object { $_.FullName -ne (Join-Path $kitRoot 'manifest.json') } | ForEach-Object { $_.FullName.Substring($kitRoot.Length + 1).Replace('\','/') })
if (@(Compare-Object $knownPaths $actualPaths).Count) { throw 'Manifest file inventory mismatch.' }
$skillRoot = Join-Path $kitRoot 'skills'
if ($InstalledRoot) { $skillRoot = [IO.Path]::GetFullPath($InstalledRoot) }
foreach ($name in $expectedNames) {
    $skillDir = Join-Path $skillRoot $name
    $text = Get-Content -LiteralPath (Join-Path $skillDir 'SKILL.md') -Raw -Encoding UTF8
    if ($text -notmatch ('(?s)^---\r?\nname: ' + [regex]::Escape($name) + '\r?\ndescription: [^\r\n]+\r?\n---')) { throw "Invalid skill metadata: $name" }
    if ($text -match '\[TODO:') { throw "Unfinished skill: $name" }
    foreach ($link in [regex]::Matches($text, '\]\(([^)]+)\)')) {
        $target = $link.Groups[1].Value
        if ($target -notmatch '^https?://' -and !(Test-Path -LiteralPath (Join-Path $skillDir $target))) { throw "Broken reference: $name/$target" }
    }
    if ($InstalledRoot) {
        foreach ($entry in $manifest.files | Where-Object { $_.path.StartsWith("skills/$name/") }) {
            $file = Join-Path $skillRoot $entry.path.Substring(7)
            if (!(Test-Path -LiteralPath $file -PathType Leaf) -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Installed file mismatch: $($entry.path)" }
        }
    }
}
if ($InstalledRoot) {
    $settings = Get-Content -LiteralPath (Join-Path $skillRoot 'max-mode-cn/settings.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($settings.schema_version -ne 1 -or $settings.language -ne 'zh-CN' -or $settings.project_knowledge -ne 'optional-explicit') { throw 'Unsupported installed configuration.' }
    if ($settings.artifact_root -and ![IO.Path]::IsPathRooted($settings.artifact_root)) { throw 'artifact_root must be absolute.' }
}
Write-Output "PASS: package integrity and six skill structures verified. Root: $skillRoot"
