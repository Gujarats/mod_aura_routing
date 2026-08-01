$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Config = Get-Content (Join-Path $Root "scripts/config/z_aura.nut") -Raw
$Loader = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_loader.nut") -Raw
$Js = Get-Content (Join-Path $Root "ui/mods/aura_routing.js") -Raw
$Readme = Get-Content (Join-Path $Root "README.md") -Raw
$Guide = Get-Content (Join-Path $Root "docs/legends_perk_system_compatibility.md") -Raw
$LegendsPatchPath = Join-Path $Root "scripts/mods/aura_routing/compatibility/legends_perk_tree_patch.nut"

if (!(Test-Path $LegendsPatchPath)) {
    throw "Missing Legends compatibility module: scripts/mods/aura_routing/compatibility/legends_perk_tree_patch.nut"
}

$LegendsPatch = Get-Content $LegendsPatchPath -Raw

function Assert-ContainsLiteral($Haystack, $Needle, $Message) {
    if (!$Haystack.Contains($Needle)) {
        throw "$Message$Needle"
    }
}

function Assert-Order($Haystack, $Earlier, $Later, $Message) {
    $earlierIndex = $Haystack.IndexOf($Earlier)
    $laterIndex = $Haystack.IndexOf($Later)

    if ($earlierIndex -lt 0) {
        throw "Missing order token: $Earlier"
    }

    if ($laterIndex -lt 0) {
        throw "Missing order token: $Later"
    }

    if ($earlierIndex -ge $laterIndex) {
        throw $Message
    }
}

foreach ($Needle in @(
    'Const = "AuraRouting"',
    '::Const.Perks.LookupMap[perk.ID] <- perk;'
)) {
    Assert-ContainsLiteral $Config $Needle "Missing Aura perk config token: "
}

foreach ($Needle in @(
    '::AuraRouting.Compatibility.Legends',
    'function registerHooks( _mod )',
    'function registerPerkDef()',
    'function getAuraRoutingPerkDefNumber()',
    'function addAuraToBackground( _background )',
    '::Const.Perks.addPerkDefObjects',
    '::Legends.Perk.AuraRouting',
    '::Const.Perks.PerkDefs.AuraRouting',
    'PerkName.AuraRouting',
    'PerkDescription.AuraRouting',
    'scripts/skills/backgrounds/character_background',
    'q.buildPerkTree',
    '_background.addPerk(',
    '_background.getPerk("perk.aura_routing")',
    '::Hooks.hasMod("mod_legends")'
)) {
    Assert-ContainsLiteral $LegendsPatch $Needle "Missing Legends compatibility module token: "
}

foreach ($Needle in @(
    'queue(">mod_msu", ">mod_legends", ">mod_necro"',
    '::include("scripts/mods/aura_routing/compatibility/legends_perk_tree_patch");',
    '::AuraRouting.Compatibility.Legends.registerHooks(mod);',
    'return result;'
)) {
    Assert-ContainsLiteral $Loader $Needle "Missing Legends compatibility loader orchestration token: "
}

Assert-Order $Loader '::AuraRouting.DeveloperOptions.grantAuraForTest(_entity);' 'if (::Hooks.hasMod("mod_legends"))' "Legends return must run after developer helpers."
Assert-Order $Loader 'if (::Hooks.hasMod("mod_legends"))' 'if (_entity != null)' "Legends return must happen before the vanilla UI perk-tree injection branch."

if ($Loader -match 'HookMod\.require\("mod_legends') {
    throw "Aura Routing must not require mod_legends."
}

foreach ($Needle in @(
    'if (this.mPerkTree)',
    'auraRoutingTree'
)) {
    Assert-ContainsLiteral $Js $Needle "Missing Aura Routing JS guard token: "
}

foreach ($Needle in @(
    'Legends Compatibility',
    'buildPerkTree',
    'save compatibility',
    'mod_aura_routing'
)) {
    if (!$Readme.Contains($Needle) -and !$Guide.Contains($Needle)) {
        throw "Missing Legends documentation token: $Needle"
    }
}

Write-Host "Aura Routing Legends compatibility static checks passed."
