$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Settings = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_settings.nut") -Raw
$Loader = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_loader.nut") -Raw
$Readme = Get-Content (Join-Path $Root "README.md") -Raw
$Docs = Get-Content (Join-Path $Root "docs/developer_options.md") -Raw
$DeveloperOptionsPath = Join-Path $Root "scripts/mods/aura_routing/developer_options.nut"

if (!(Test-Path $DeveloperOptionsPath)) {
    throw "Missing developer options module: scripts/mods/aura_routing/developer_options.nut"
}

$DeveloperOptions = Get-Content $DeveloperOptionsPath -Raw

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
    'addBooleanSetting\(\s*"DebugLogging"\s*,\s*false',
    'addBooleanSetting\(\s*"EnableDeveloperOptions"\s*,\s*false',
    'addBooleanSetting\(\s*"DeveloperGrantAuraOnLoad"\s*,\s*false',
    'addBooleanSetting\(\s*"DeveloperGrantResourcesOnLoad"\s*,\s*false'
)

foreach ($Pattern in $RequiredSettingPatterns) {
    Assert-Matches $Settings $Pattern "Missing developer setting pattern: "
}

foreach ($Needle in @(
    'debugLogging.addCallback',
    '::AuraRouting.DeveloperOptions.configureDebugLogging();'
)) {
    Assert-ContainsLiteral $Settings $Needle "Missing developer setting callback token: "
}

$RequiredDeveloperModuleTokens = @(
    '::AuraRouting.DeveloperOptions',
    '::AuraRouting.DeveloperSession',
    'function init()',
    'function isEnabled()',
    'function configureDebugLogging()',
    'DebugLogging',
    'Debug.setFlag("default"',
    'function applyResourcesOnce()',
    'function grantAuraForTest( _entity )',
    'DeveloperGrantAuraOnLoad',
    'DeveloperGrantResourcesOnLoad',
    'background.addPerk('
)

foreach ($Needle in $RequiredDeveloperModuleTokens) {
    Assert-ContainsLiteral $DeveloperOptions $Needle "Missing developer module token: "
}

if ($DeveloperOptions -match 'Debug\.enable\(\)|Debug\.disable\(\)') {
    throw "Aura Routing debug logging must use Debug.setFlag callback, not Debug.enable()/disable()."
}

$RequiredLoaderTokens = @(
    '::include("scripts/mods/aura_routing/developer_options");',
    '::AuraRouting.DeveloperOptions.init();',
    '::AuraRouting.DeveloperOptions.applyResourcesOnce();',
    '::AuraRouting.DeveloperOptions.grantAuraForTest(_entity);'
)

foreach ($Needle in $RequiredLoaderTokens) {
    Assert-ContainsLiteral $Loader $Needle "Missing developer loader orchestration token: "
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
