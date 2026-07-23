$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot

function Require-Token {
    param(
        [string] $Path,
        [string[]] $Tokens
    )

    $fullPath = Join-Path $projectRoot $Path
    if (!(Test-Path -LiteralPath $fullPath)) {
        throw "Missing required file: $Path"
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    foreach ($token in $Tokens) {
        if (!$content.Contains($token)) {
            throw "Missing token in ${Path}: $token"
        }
    }
}

function Forbid-Token {
    param(
        [string] $Path,
        [string[]] $Tokens
    )

    $fullPath = Join-Path $projectRoot $Path
    if (!(Test-Path -LiteralPath $fullPath)) {
        return
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    foreach ($token in $Tokens) {
        if ($content.Contains($token)) {
            throw "Forbidden token in ${Path}: $token"
        }
    }
}

Require-Token 'scripts/!mods_preload/mod_aura_routing_settings.nut' @(
    'local general = ::AuraRouting.Mod.ModSettings.addPage("General");',
    'local attack = ::AuraRouting.Mod.ModSettings.addPage("Attack");',
    'local morale = ::AuraRouting.Mod.ModSettings.addPage("Morale");',
    'local fallback = ::AuraRouting.Mod.ModSettings.addPage("Fallback Defense");',
    'general.addRangeSetting("UsesPerBattle"',
    '"PerkLevel"',
    'morale.addRangeSetting("MoraleResolvePenalty", 10, 0, 50, 1',
    'morale.addRangeSetting("MoraleDropSteps", 1, 1, 3, 1',
    'morale.addBooleanSetting("AllowFleeingOnAlreadyWavering", true',
    'attack.addRangeSetting("AttackHitChanceBonus", 0, -30, 30, 1',
    'attack.addRangeSetting("AttackDamageMin", 15, 0, 100, 1',
    'attack.addRangeSetting("AttackDamageMax", 30, 0, 150, 1',
    'attack.addRangeSetting("AttackArmorDamageMultPct", 75, 0, 200, 5',
    'attack.addRangeSetting("AttackDirectDamagePct", 10, 0, 100, 1',
    'fallback.addRangeSetting("NoAffectedMeleeDefense", 35, 0, 100, 1',
    'fallback.addRangeSetting("NoAffectedRangedDefense", 25, 0, 100, 1',
    'fallback.addRangeSetting("OneAffectedMeleeDefense", 20, 0, 100, 1',
    'fallback.addRangeSetting("OneAffectedRangedDefense", 15, 0, 100, 1',
    'fallback.addRangeSetting("TwoAffectedMeleeDefense", 10, 0, 100, 1',
    'fallback.addRangeSetting("TwoAffectedRangedDefense", 5, 0, 100, 1'
)

Require-Token 'scripts/skills/effects/aura_routing_evasion_effect.nut' @(
    'effects.aura_routing_evasion',
    'function setDefense( _meleeDefense, _rangedDefense )',
    '_properties.MeleeDefense += this.m.MeleeDefenseBonus;',
    '_properties.RangedDefense += this.m.RangedDefenseBonus;',
    'function onTurnStart()',
    'this.removeSelf();'
)

Require-Token 'scripts/skills/actives/aura_routing_skill.nut' @(
    'actives.aura_routing',
    'function collectArcTiles( _user, _targetTile )',
    'function canAffectMorale( _entity )',
    'function onAnySkillUsed( _skill, _targetEntity, _properties )',
    'function onTargetHit( _skill, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor )',
    'function onTargetMissed( _skill, _targetEntity )',
    'function tryDropMorale( _user, _entity )',
    'function applyFallbackEvasion( _user, _affectedCount )',
    'this.skill.isUsable()',
    'this.m.IsUsingHitchance = true;',
    'this.m.HitChanceBonus = ::AuraRouting.Mod.ModSettings.getSetting("AttackHitChanceBonus").getValue();',
    '_properties.DamageRegularMin = minDamage;',
    '_properties.DamageRegularMax = maxDamage;',
    '_properties.DamageArmorMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackArmorDamageMultPct").getValue() / 100.0;',
    'this.m.DirectDamageMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackDirectDamagePct").getValue() / 100.0;',
    '::new("scripts/skills/effects/aura_routing_evasion_effect")',
    'affectedCount++',
    'return affectedCount > 0 || evasionApplied;'
)

Forbid-Token 'scripts/skills/actives/aura_routing_skill.nut' @(
    'entity.setMoraleState(this.Const.MoraleState.Fleeing);',
    'function isUsingHitchance()',
    'text = "Has 100% chance to hit"'
)

Require-Token 'README.md' @(
    'Aura Routing attacks up to three enemies in a frontal arc using normal hit chance.',
    'Attack Hit Chance Bonus',
    'No Effect Melee/Ranged Defense'
)

Write-Host 'Aura Routing layout validation passed.'
