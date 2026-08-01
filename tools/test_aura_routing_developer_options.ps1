$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Settings = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_settings.nut") -Raw
$Loader = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_loader.nut") -Raw
$Readme = Get-Content (Join-Path $Root "README.md") -Raw
$Docs = Get-Content (Join-Path $Root "docs/developer_options.md") -Raw

function Assert-ContainsLiteral($Haystack, $Needle, $Message) {
    if (!$Haystack.Contains($Needle)) {
        throw "$Message$Needle"
    }
}

function Assert-Matches($Haystack, $Pattern, $Message) {
    if ($Haystack -notmatch $Pattern) {
        throw "$Message$Pattern"
    }
}

Assert-ContainsLiteral $Settings 'addPage("Developer Options")' "Missing developer setting token: "

$RequiredSettingPatterns = @(
    'addBooleanSetting\(\s*"EnableDeveloperOptions"\s*,\s*false',
    'addBooleanSetting\(\s*"DeveloperGrantAuraOnLoad"\s*,\s*false',
    'addBooleanSetting\(\s*"DeveloperGrantResourcesOnLoad"\s*,\s*false'
)

foreach ($Pattern in $RequiredSettingPatterns) {
    Assert-Matches $Settings $Pattern "Missing developer setting pattern: "
}

$RequiredLoaderTokens = @(
    '::AuraRouting.DeveloperSession',
    'function isAuraRoutingDeveloperOptionsEnabled()',
    'function applyAuraRoutingDeveloperResourcesOnce()',
    'function findAuraRoutingLegendsPerkDefNumber()',
    'function grantAuraRoutingForDeveloperTest(',
    'DeveloperGrantAuraOnLoad',
    'DeveloperGrantResourcesOnLoad',
    'background.addPerk('
)

foreach ($Needle in $RequiredLoaderTokens) {
    Assert-ContainsLiteral $Loader $Needle "Missing developer loader token: "
}

if ($Loader -match 'addSQKeybind|addJSKeybind') {
    throw "Developer options must not add a hotkey in the first version."
}

foreach ($Needle in @('Developer Options', 'EnableDeveloperOptions', 'disposable test saves')) {
    if (!$Readme.Contains($Needle) -and !$Docs.Contains($Needle)) {
        throw "Missing documentation token: $Needle"
    }
}

Write-Host "Aura Routing developer options static checks passed."
