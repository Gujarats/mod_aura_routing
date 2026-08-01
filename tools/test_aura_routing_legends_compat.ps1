$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Config = Get-Content (Join-Path $Root "scripts/config/z_aura.nut") -Raw
$Loader = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_loader.nut") -Raw
$Js = Get-Content (Join-Path $Root "ui/mods/aura_routing.js") -Raw
$Readme = Get-Content (Join-Path $Root "README.md") -Raw
$Guide = Get-Content (Join-Path $Root "docs/legends_perk_system_compatibility.md") -Raw

function Assert-ContainsLiteral($Haystack, $Needle, $Message) {
    if (!$Haystack.Contains($Needle)) {
        throw "$Message$Needle"
    }
}

foreach ($Needle in @(
    'Const = "AuraRouting"',
    '::Const.Perks.LookupMap[perk.ID] <- perk;'
)) {
    Assert-ContainsLiteral $Config $Needle "Missing Aura perk config token: "
}

foreach ($Needle in @(
    'queue(">mod_msu", ">mod_legends", ">mod_necro"',
    'function registerAuraRoutingPerkDefForLegends()',
    '::Const.Perks.addPerkDefObjects',
    '::Legends.Perk.AuraRouting',
    '::Const.Perks.PerkDefs.AuraRouting',
    'PerkName.AuraRouting',
    'PerkDescription.AuraRouting',
    'scripts/skills/backgrounds/character_background',
    'q.buildPerkTree',
    'this.addPerk(auraRoutingLegendsPerkDef',
    'this.getPerk("perk.aura_routing")',
    '::Hooks.hasMod("mod_legends")',
    'return result;'
)) {
    Assert-ContainsLiteral $Loader $Needle "Missing Legends compatibility loader token: "
}

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
