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
    'PreviousPermanentInjury4Brush = null',
    'PreviousPermanentInjury4Visible = false',
    'PreviousPermanentInjury4Alpha = 255',
    'PulseToken = 0',
    'PulseStartMs = 0',
    'PulsePeriodMs = 1200',
    'PulseMinAlpha = 90',
    'PulseMaxAlpha = 255',
    'PulseTickMs = 60',
    'function showFallbackEyes()',
    'function hideFallbackEyes()',
    'function startFallbackEyesPulse()',
    'function stopFallbackEyesPulse()',
    'function fallbackEyesPulseTick( _ctx )',
    'this.doesBrushExist("zombie_rage_eyes")',
    'actor.hasSprite("permanent_injury_4")',
    'sprite.setBrush("zombie_rage_eyes");',
    'sprite.fadeIn(1500);',
    'sprite.fadeOutAndHide(1500);',
    'sprite.Alpha = alpha.tointeger();',
    '::Time.scheduleEvent(::TimeUnit.Real, this.m.PulseTickMs, this.fallbackEyesPulseTick.bindenv(this), _ctx);',
    'Aura Fallback Eyes: applying zombie_rage_eyes',
    'Aura Fallback Eyes: pulse started',
    'Aura Fallback Eyes: pulse stopped',
    'Aura Fallback Eyes: missing permanent_injury_4 sprite',
    'Aura Fallback Eyes: missing zombie_rage_eyes brush',
    'Aura Fallback Eyes: removed',
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
    'function isTileInSelectedArc( _user, _targetTile )',
    'function getMoraleChangeForPreview( _entity )',
    'function getMoraleResistChancePct( _user, _entity )',
    'function getMoraleDropChanceOnHitPct( _user, _entity )',
    'function getAuraRoutingTargetTooltip( _targetEntity )',
    'function applyFallbackEvasion( _user, _affectedCount )',
    'function onTargetDeselected()',
    'this.Tactical.getHighlighter().clearOverlayIcons();',
    'this.skill.isUsable()',
    'this.m.IsUsingHitchance = true;',
    'this.m.HitChanceBonus = ::AuraRouting.Mod.ModSettings.getSetting("AttackHitChanceBonus").getValue();',
    '_properties.DamageRegularMin = minDamage;',
    '_properties.DamageRegularMax = maxDamage;',
    '_properties.DamageArmorMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackArmorDamageMultPct").getValue() / 100.0;',
    'this.m.DirectDamageMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackDirectDamagePct").getValue() / 100.0;',
    'Mirrors Battle Brothers 1.5.2.3 data_001 actor.checkMorale',
    'local score = bravery + difficulty - numOpponentsAdjacent * this.Const.Morale.OpponentsAdjacentMult + numAlliesAdjacent * this.Const.Morale.AlliesAdjacentMult - threatBonus;',
    'local resistChance = baseResist + (100 - baseResist) * rerollChance * baseResist / 10000;',
    '"Morale drop on hit: [color=" + this.Const.UI.Color.PositiveValue + "]" + dropChance + "%[/color]"',
    '::new("scripts/skills/effects/aura_routing_evasion_effect")',
    'function spawnHolyBarrierPulseFrame( _ctx )',
    'function spawnHolyBarrierPulse( _tile )',
    'brush = "aura_holy_barrier_01"',
    'brush = "aura_holy_barrier_02"',
    'brush = "aura_holy_barrier_03"',
    '::Time.scheduleEvent(::TimeUnit.Real, 90, this.spawnHolyBarrierPulseFrame.bindenv(this),',
    '::Time.scheduleEvent(::TimeUnit.Real, 180, this.spawnHolyBarrierPulseFrame.bindenv(this),',
    'this.Tactical.spawnSpriteEffect(_ctx.brush, this.createColor("#ffffff"), _ctx.tile',
    'affectedCount++',
    'return affectedCount > 0 || evasionApplied;'
)

Require-Token 'unpacked_brushes/aura_routing_effect/metadata.xml' @(
    '<sprite id="aura_holy_barrier_01"',
    '<sprite id="aura_holy_barrier_02"',
    '<sprite id="aura_holy_barrier_03"',
    '<sprite id="aura_holy_barrier_04"',
    '<sprite id="aura_holy_barrier_05"',
    '<sprite id="aura_holy_barrier_06"',
    '<sprite id="aura_holy_barrier_07"',
    '<sprite id="aura_holy_barrier_08"'
)

Require-Token 'scripts/!mods_preload/mod_aura_routing_loader.nut' @(
    'mod.hook("scripts/entity/tactical/actor", function(q)',
    'q.getTooltip = @(__original) function( _targetedWithSkill = null )',
    '_targetedWithSkill.getID() == "actives.aura_routing"',
    'local auraRoutingLines = _targetedWithSkill.getAuraRoutingTargetTooltip(this);',
    'tooltip.push(line);'
)

Forbid-Token 'scripts/skills/actives/aura_routing_skill.nut' @(
    'ui/icons/uses.png',
    'actor.setSpriteOffset("miniboss"',
    'glow.setBrush("aura_body_glow_v2");',
    'entity.setMoraleState(this.Const.MoraleState.Fleeing);',
    'function isUsingHitchance()',
    'text = "Has 100% chance to hit"',
    'Total morale drop chance'
)

Forbid-Token 'scripts/skills/effects/aura_routing_evasion_effect.nut' @(
    'actor.setSpriteOffset("miniboss"',
    'glow.setBrush("aura_body_glow_v2");',
    'function pulseTick('
)

Require-Token 'README.md' @(
    'Aura Routing attacks up to three enemies in a frontal arc using normal hit chance.',
    'Attack Hit Chance Bonus',
    'No Effect Melee/Ranged Defense',
    'When Aura Routing is selected, hovering a highlighted enemy shows its morale drop chance on hit.',
    'The morale preview formula mirrors Battle Brothers 1.5.2.3 data_001 scripts/entity/tactical/actor.nut checkMorale().',
    'If the base game or another mod changes checkMorale(), the preview can become inaccurate and must be updated.'
)

Write-Host 'Aura Routing layout validation passed.'
