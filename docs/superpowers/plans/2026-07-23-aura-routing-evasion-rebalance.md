# Aura Routing Evasion Rebalance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebalance Aura Routing so it no longer guarantees enemy routing, and instead grants a configurable temporary defense fallback when the morale effect underperforms.

**Architecture:** Keep Aura Routing as a targeted 3-tile arc active skill. Replace direct `Fleeing` assignment with a real hit-chance attack: each valid enemy is attacked, normal hit/miss resolution decides whether armor and hitpoints are damaged, and only a landed hit can trigger the follow-up resolve check. Count enemies whose morale actually drops after a landed hit, then apply a temporary `Aura Evasion` effect to the caster until their next turn based on that count. Add MSU settings for every new balance number so players can tune the skill without editing scripts.

**Tech Stack:** Battle Brothers Squirrel `.nut` scripts, Modern Hooks, MSU settings, existing Aura Routing UI/perk integration.

## Global Constraints

- Do not force all valid enemies directly to `Fleeing`.
- Aura Routing must use normal hit-chance calculation; it must not bypass hit chance with guaranteed hits.
- A landed Aura Routing attack must be able to damage enemy armor and hitpoints before the morale check is resolved.
- Missed attacks must not damage the enemy and must not trigger the morale check.
- Count an enemy as affected only when the aura attack hits and its morale state actually worsens.
- Fallback defense lasts until the caster's next turn and is not consumed by attacks or misses.
- Fallback defense modifies normal `MeleeDefense` and `RangedDefense`; it must not force enemies to miss.
- Add MSU options for all new balance numbers.
- Preserve existing perk ID `perk.aura_routing`, active skill ID `actives.aura_routing`, icon paths, perk-tree injection, and `UsesPerBattle` / `PerkLevel` settings.
- Keep the skill as a 3-tile arc around the selected adjacent tile unless the user explicitly approves a radius redesign later.
- Add undead/fearless safety guards before applying morale changes.

---

## File Structure

- `scripts/!mods_preload/mod_aura_routing_settings.nut`: owns MSU settings. Add configurable morale and fallback-defense values here.
- `scripts/skills/actives/aura_routing_skill.nut`: owns target collection, morale checks, affected-count logic, visual effects, charge consumption, and tooltip.
- `scripts/skills/effects/aura_routing_evasion_effect.nut`: new temporary effect that adds configured defense until the caster's next turn.
- `tools/test_aura_routing_layout.ps1`: create a static validator for required files, settings, IDs, and safety guards if no validator exists yet.
- `README.md`: update player-facing description and settings list.

### Task 1: Add Configurable Balance Settings

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_settings.nut`
- Test/Create: `mod_aura_routing/tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes: `::AuraRouting.Mod.ModSettings.addPage("General")`
- Produces: MSU settings read by `aura_routing_skill.nut`:
  - `MoraleResolvePenalty`
  - `MoraleDropSteps`
  - `AllowFleeingOnAlreadyWavering`
  - `AttackHitChanceBonus`
  - `AttackDamageMin`
  - `AttackDamageMax`
  - `AttackArmorDamageMultPct`
  - `AttackDirectDamagePct`
  - `NoAffectedMeleeDefense`
  - `NoAffectedRangedDefense`
  - `OneAffectedMeleeDefense`
  - `OneAffectedRangedDefense`
  - `TwoAffectedMeleeDefense`
  - `TwoAffectedRangedDefense`

- [ ] **Step 1: Write static validator expectations**

Create or extend `mod_aura_routing/tools/test_aura_routing_layout.ps1` with required token assertions for these setting declarations:

```powershell
'page.addRangeSetting("MoraleResolvePenalty", 10, 0, 50, 1'
'page.addRangeSetting("MoraleDropSteps", 1, 1, 3, 1'
'page.addBooleanSetting("AllowFleeingOnAlreadyWavering", true'
'page.addRangeSetting("AttackHitChanceBonus", 0, -30, 30, 1'
'page.addRangeSetting("AttackDamageMin", 15, 0, 100, 1'
'page.addRangeSetting("AttackDamageMax", 30, 0, 150, 1'
'page.addRangeSetting("AttackArmorDamageMultPct", 75, 0, 200, 5'
'page.addRangeSetting("AttackDirectDamagePct", 10, 0, 100, 1'
'page.addRangeSetting("NoAffectedMeleeDefense", 35, 0, 100, 1'
'page.addRangeSetting("NoAffectedRangedDefense", 25, 0, 100, 1'
'page.addRangeSetting("OneAffectedMeleeDefense", 20, 0, 100, 1'
'page.addRangeSetting("OneAffectedRangedDefense", 15, 0, 100, 1'
'page.addRangeSetting("TwoAffectedMeleeDefense", 10, 0, 100, 1'
'page.addRangeSetting("TwoAffectedRangedDefense", 5, 0, 100, 1'
```

- [ ] **Step 2: Run validator and confirm it fails**

Run from `mod_aura_routing`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: failure because the new settings and effect file do not exist yet.

- [ ] **Step 3: Add MSU settings**

In `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_settings.nut`, after `UsesPerBattle`, add:

```squirrel
page.addRangeSetting(
    "MoraleResolvePenalty",
    10, 0, 50, 1,
    "Morale Resolve Penalty",
    "Penalty applied to enemy Resolve checks made against Aura Routing."
);

page.addRangeSetting(
    "MoraleDropSteps",
    1, 1, 3, 1,
    "Morale Drop Steps",
    "How many morale steps an enemy loses after failing the Aura Routing resolve check."
);

page.addBooleanSetting(
    "AllowFleeingOnAlreadyWavering",
    true,
    "Fleeing From Wavering",
    "When enabled, enemies already Wavering can become Fleeing after failing the Aura Routing resolve check."
);

page.addRangeSetting("AttackHitChanceBonus", 0, -30, 30, 1, "Attack Hit Chance Bonus", "Flat hit chance modifier for Aura Routing attacks.");
page.addRangeSetting("AttackDamageMin", 15, 0, 100, 1, "Attack Minimum Damage", "Minimum regular damage for a landed Aura Routing attack.");
page.addRangeSetting("AttackDamageMax", 30, 0, 150, 1, "Attack Maximum Damage", "Maximum regular damage for a landed Aura Routing attack.");
page.addRangeSetting("AttackArmorDamageMultPct", 75, 0, 200, 5, "Attack Armor Damage (%)", "Armor damage multiplier for a landed Aura Routing attack.");
page.addRangeSetting("AttackDirectDamagePct", 10, 0, 100, 1, "Attack Direct Damage (%)", "Share of regular damage that can pass through armor on a landed Aura Routing attack.");

page.addRangeSetting("NoAffectedMeleeDefense", 35, 0, 100, 1, "No Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects no enemies.");
page.addRangeSetting("NoAffectedRangedDefense", 25, 0, 100, 1, "No Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects no enemies.");
page.addRangeSetting("OneAffectedMeleeDefense", 20, 0, 100, 1, "One Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects one enemy.");
page.addRangeSetting("OneAffectedRangedDefense", 15, 0, 100, 1, "One Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects one enemy.");
page.addRangeSetting("TwoAffectedMeleeDefense", 10, 0, 100, 1, "Two Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects two enemies.");
page.addRangeSetting("TwoAffectedRangedDefense", 5, 0, 100, 1, "Two Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects two enemies.");
```

- [ ] **Step 4: Run validator**

Run from `mod_aura_routing`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: setting assertions pass; later task assertions may still fail until those files are implemented.

### Task 2: Add Aura Evasion Effect

**Files:**
- Create: `mod_aura_routing/scripts/skills/effects/aura_routing_evasion_effect.nut`
- Modify: `mod_aura_routing/tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes: `effect.setDefense(_meleeDefense, _rangedDefense)`
- Produces: effect ID `effects.aura_routing_evasion`

- [ ] **Step 1: Add validator expectations for the effect**

Add required tokens:

```powershell
'effects.aura_routing_evasion'
'function setDefense( _meleeDefense, _rangedDefense )'
'_properties.MeleeDefense += this.m.MeleeDefenseBonus;'
'_properties.RangedDefense += this.m.RangedDefenseBonus;'
'function onTurnStart()'
'this.removeSelf();'
```

- [ ] **Step 2: Create the effect**

Create `mod_aura_routing/scripts/skills/effects/aura_routing_evasion_effect.nut`:

```squirrel
this.aura_routing_evasion_effect <- this.inherit("scripts/skills/skill", {
    m = {
        MeleeDefenseBonus = 0,
        RangedDefenseBonus = 0
    },

    function create()
    {
        this.m.ID = "effects.aura_routing_evasion";
        this.m.Name = "Aura Evasion";
        this.m.Description = "The unused force of Aura Routing bends incoming attacks aside until this character's next turn.";
        this.m.Icon = "skills/status_effect_08.png";
        this.m.IconMini = "status_effect_08_mini";
        this.m.Type = this.Const.SkillType.StatusEffect;
        this.m.IsActive = false;
        this.m.IsHidden = false;
        this.m.IsRemovedAfterBattle = true;
    }

    function setDefense( _meleeDefense, _rangedDefense )
    {
        this.m.MeleeDefenseBonus = this.Math.max(0, _meleeDefense);
        this.m.RangedDefenseBonus = this.Math.max(0, _rangedDefense);
    }

    function getTooltip()
    {
        local ret = this.skill.getTooltip();
        ret.push({
            id = 10,
            type = "text",
            icon = "ui/icons/melee_defense.png",
            text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.m.MeleeDefenseBonus + "[/color] Melee Defense until next turn"
        });
        ret.push({
            id = 11,
            type = "text",
            icon = "ui/icons/ranged_defense.png",
            text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.m.RangedDefenseBonus + "[/color] Ranged Defense until next turn"
        });
        return ret;
    }

    function onUpdate( _properties )
    {
        _properties.MeleeDefense += this.m.MeleeDefenseBonus;
        _properties.RangedDefense += this.m.RangedDefenseBonus;
    }

    function onTurnStart()
    {
        this.removeSelf();
    }
});
```

- [ ] **Step 3: Run validator**

Run from `mod_aura_routing`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: effect assertions pass; active-skill assertions may still fail until Task 3.

### Task 3: Rebalance Aura Routing Active Skill

**Files:**
- Modify: `mod_aura_routing/scripts/skills/actives/aura_routing_skill.nut`
- Modify: `mod_aura_routing/tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes: MSU settings from Task 1 and `scripts/skills/effects/aura_routing_evasion_effect`
- Produces:
  - `collectArcTiles(_user, _targetTile)` returns tile array.
  - `canAffectMorale(_entity)` returns boolean.
  - `onTargetHit(_skill, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor)` records landed Aura Routing hits.
  - `onTargetMissed(_skill, _targetEntity)` records missed Aura Routing attacks.
  - `tryDropMorale(_user, _entity)` runs only after a landed Aura Routing hit and returns boolean.
  - `applyFallbackEvasion(_user, _affectedCount)` returns no value.

- [ ] **Step 1: Add validator expectations**

Add required tokens:

```powershell
'function collectArcTiles( _user, _targetTile )'
'function canAffectMorale( _entity )'
'function onAnySkillUsed( _skill, _targetEntity, _properties )'
'function onTargetHit( _skill, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor )'
'function onTargetMissed( _skill, _targetEntity )'
'function tryDropMorale( _user, _entity )'
'function applyFallbackEvasion( _user, _affectedCount )'
'this.skill.isUsable()'
'this.m.IsUsingHitchance = true;'
'this.m.HitChanceBonus = ::AuraRouting.Mod.ModSettings.getSetting("AttackHitChanceBonus").getValue();'
'_properties.DamageRegularMin = ::AuraRouting.Mod.ModSettings.getSetting("AttackDamageMin").getValue();'
'_properties.DamageRegularMax = ::AuraRouting.Mod.ModSettings.getSetting("AttackDamageMax").getValue();'
'_properties.DamageArmorMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackArmorDamageMultPct").getValue() / 100.0;'
'this.m.DirectDamageMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackDirectDamagePct").getValue() / 100.0;'
'::new("scripts/skills/effects/aura_routing_evasion_effect")'
'affectedCount++'
'return affectedCount > 0 || evasionApplied;'
```

Add forbidden tokens:

```powershell
'entity.setMoraleState(this.Const.MoraleState.Fleeing);'
'function isUsingHitchance()'
'text = "Has 100% chance to hit"'
```

- [ ] **Step 2: Fix usability**

In `create()`, ensure hit chance is enabled and add hit-tracking fields:

```squirrel
this.m.IsUsingHitchance = true;
this.m.LastAuraRoutingHits <- {};
this.m.LastAuraRoutingMisses <- {};
```

Then change `isUsable()` to respect base skill constraints:

```squirrel
function isUsable()
{
    if (!this.skill.isUsable()) return false;
    if (this.m.Charges <= 0) return false;
    return this.m.Container.getActor().getActionPoints() >= this.m.ActionPointCost;
}
```

- [ ] **Step 3: Add configurable attack stats**

Add:

```squirrel
function onAnySkillUsed( _skill, _targetEntity, _properties )
{
    if (_skill != this) return;

    local minDamage = ::AuraRouting.Mod.ModSettings.getSetting("AttackDamageMin").getValue();
    local maxDamage = ::AuraRouting.Mod.ModSettings.getSetting("AttackDamageMax").getValue();
    if (maxDamage < minDamage) maxDamage = minDamage;

    this.m.HitChanceBonus = ::AuraRouting.Mod.ModSettings.getSetting("AttackHitChanceBonus").getValue();
    this.m.DirectDamageMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackDirectDamagePct").getValue() / 100.0;
    _properties.DamageRegularMin = minDamage;
    _properties.DamageRegularMax = maxDamage;
    _properties.DamageArmorMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackArmorDamageMultPct").getValue() / 100.0;
}
```

- [ ] **Step 4: Add hit/miss tracking**

Add:

```squirrel
function getEntityHitKey( _entity )
{
    if (_entity == null) return "";
    return _entity.getID().tostring();
}

function onTargetHit( _skill, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor )
{
    if (_skill != this || _targetEntity == null) return;
    this.m.LastAuraRoutingHits[this.getEntityHitKey(_targetEntity)] <- true;
}

function onTargetMissed( _skill, _targetEntity )
{
    if (_skill != this || _targetEntity == null) return;
    this.m.LastAuraRoutingMisses[this.getEntityHitKey(_targetEntity)] <- true;
}

function didLastAttackHit( _entity )
{
    local key = this.getEntityHitKey(_entity);
    return key in this.m.LastAuraRoutingHits;
}
```

- [ ] **Step 5: Add target collection helper**

Add:

```squirrel
function collectArcTiles( _user, _targetTile )
{
    local ownTile = _user.getTile();
    local dir = ownTile.getDirectionTo(_targetTile);
    local tiles = [ _targetTile ];

    for (local i = 1; i < 3; i++)
    {
        local nextDir = (dir - i) % this.Const.Direction.COUNT;
        if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
        if (ownTile.hasNextTile(nextDir))
        {
            local nextTile = ownTile.getNextTile(nextDir);
            if (this.Math.abs(nextTile.Level - ownTile.Level) <= 1)
            {
                tiles.push(nextTile);
            }
        }
    }

    return tiles;
}
```

- [ ] **Step 6: Add morale safety helper**

Add:

```squirrel
function canAffectMorale( _entity )
{
    if (_entity == null || !_entity.isAlive()) return false;
    if ("isNonCombatant" in _entity && _entity.isNonCombatant()) return false;

    local flags = _entity.getFlags();
    if (flags != null && flags.has("undead")) return false;

    local skills = _entity.getSkills();
    if (skills != null)
    {
        if (skills.hasSkill("effects.morale_check")) return false;
        if (skills.hasSkill("effects.legend_fearless")) return false;
    }

    return true;
}
```

- [ ] **Step 7: Add resolve-based morale drop**

Add:

```squirrel
function tryDropMorale( _user, _entity )
{
    if (!this.didLastAttackHit(_entity)) return false;
    if (!this.canAffectMorale(_entity)) return false;

    local before = _entity.getMoraleState();
    if (before == this.Const.MoraleState.Fleeing) return false;

    local penalty = ::AuraRouting.Mod.ModSettings.getSetting("MoraleResolvePenalty").getValue();
    local roll = this.Math.rand(1, 100);
    local target = _entity.getCurrentProperties().Bravery - penalty;
    if (roll <= target)
    {
        return false;
    }

    local steps = ::AuraRouting.Mod.ModSettings.getSetting("MoraleDropSteps").getValue();
    local after = before;
    for (local i = 0; i < steps; ++i)
    {
        if (after == this.Const.MoraleState.Wavering
            && !::AuraRouting.Mod.ModSettings.getSetting("AllowFleeingOnAlreadyWavering").getValue())
        {
            break;
        }

        if (after < this.Const.MoraleState.Fleeing)
        {
            after++;
        }
    }

    if (after == before) return false;
    _entity.setMoraleState(after);
    return true;
}
```

- [ ] **Step 8: Add fallback evasion**

Add:

```squirrel
function applyFallbackEvasion( _user, _affectedCount )
{
    local melee = 0;
    local ranged = 0;

    if (_affectedCount == 0)
    {
        melee = ::AuraRouting.Mod.ModSettings.getSetting("NoAffectedMeleeDefense").getValue();
        ranged = ::AuraRouting.Mod.ModSettings.getSetting("NoAffectedRangedDefense").getValue();
    }
    else if (_affectedCount == 1)
    {
        melee = ::AuraRouting.Mod.ModSettings.getSetting("OneAffectedMeleeDefense").getValue();
        ranged = ::AuraRouting.Mod.ModSettings.getSetting("OneAffectedRangedDefense").getValue();
    }
    else if (_affectedCount == 2)
    {
        melee = ::AuraRouting.Mod.ModSettings.getSetting("TwoAffectedMeleeDefense").getValue();
        ranged = ::AuraRouting.Mod.ModSettings.getSetting("TwoAffectedRangedDefense").getValue();
    }

    if (melee <= 0 && ranged <= 0) return false;

    local skills = _user.getSkills();
    skills.removeByID("effects.aura_routing_evasion");
    local effect = ::new("scripts/skills/effects/aura_routing_evasion_effect");
    effect.setDefense(melee, ranged);
    skills.add(effect);
    return true;
}
```

- [ ] **Step 9: Update `onUse`**

Replace forced-fleeing execution with affected counting:

```squirrel
local tiles = this.collectArcTiles(_user, _targetTile);
local hasEnemy = false;
local affectedCount = 0;
this.m.LastAuraRoutingHits.clear();
this.m.LastAuraRoutingMisses.clear();

foreach (tile in tiles)
{
    if (!tile.IsOccupiedByActor) continue;
    local entity = tile.getEntity();
    if (entity == null || !entity.isAlive() || entity.isAlliedWith(_user)) continue;
    hasEnemy = true;

    this.attackEntity(_user, entity);
    if (this.tryDropMorale(_user, entity))
    {
        affectedCount++;
    }
}

if (!hasEnemy) return false;

local evasionApplied = this.applyFallbackEvasion(_user, affectedCount);
this.m.Charges = this.Math.max(0, this.m.Charges - 1);
return affectedCount > 0 || evasionApplied;
```

- [ ] **Step 10: Update tooltip**

Replace guaranteed-hit copy with:

```squirrel
{
    id = 6,
    type = "text",
    icon = "ui/icons/bravery.png",
    text = "Each enemy is attacked normally. Landed hits can damage armor and hitpoints, then force a Resolve check. If few enemies are affected, the user gains temporary defense until their next turn."
}
```

- [ ] **Step 11: Run validator**

Run from `mod_aura_routing`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: all static assertions pass.

### Task 4: Update Documentation and Build

**Files:**
- Modify: `mod_aura_routing/README.md`
- Modify: `mod_aura_routing/docs/superpowers/plans/2026-07-23-aura-routing-evasion-rebalance.md` only if review finds ambiguity
- Generated: `mod_aura_routing/release/mod_aura_routing.zip` if the build script writes there

**Interfaces:**
- Consumes: settings and behavior from Tasks 1-3.
- Produces: player-facing docs that match the new skill behavior.

- [ ] **Step 1: Update README feature description**

Replace guaranteed routing language with:

```markdown
Aura Routing attacks up to three enemies in a frontal arc using normal hit chance. Landed hits can damage armor and hitpoints, then force a Resolve check; enemies that fail lose morale, and enemies already near breaking can be forced into flight depending on settings. If the aura fails to affect many enemies, unused force returns to the caster as temporary Melee and Ranged Defense until their next turn.
```

- [ ] **Step 2: Update settings list**

Document these options:

```markdown
- Uses Per Battle
- Perk Level
- Morale Resolve Penalty
- Morale Drop Steps
- Fleeing From Wavering
- Attack Hit Chance Bonus
- Attack Minimum/Maximum Damage
- Attack Armor Damage
- Attack Direct Damage
- No Effect Melee/Ranged Defense
- One Effect Melee/Ranged Defense
- Two Effect Melee/Ranged Defense
```

- [ ] **Step 3: Run validator**

Run from `mod_aura_routing`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: `Aura Routing layout validation passed.`

- [ ] **Step 4: Build release**

Run from `mod_aura_routing`:

```powershell
python .\build_mod.py
```

Expected: refreshed release archive for Aura Routing.

- [ ] **Step 5: Manual test matrix**

In Battle Brothers, test:

```text
1. No enemies in arc: skill cannot be used or returns false without consuming a charge.
2. Three valid living enemies in arc: hit chance is rolled separately for each enemy, landed hits damage armor/hitpoints, resolve checks run only after landed hits, morale drops are counted, charge consumed once.
3. Zero affected enemies: caster gains configured 0-affected defense effect until next turn.
4. One affected enemy: caster gains configured 1-affected defense effect until next turn.
5. Two affected enemies: caster gains configured 2-affected defense effect until next turn.
6. Three affected enemies: no fallback defense is applied.
7. Enemy misses caster while effect is active: effect remains.
8. Enemy hits caster while effect is active: effect remains.
9. Caster's next turn starts: effect is removed.
10. Undead/fearless targets: hit chance and damage can still resolve if the attack lands, but no crash and no forced morale change.
```

## Self-Review

- Spec coverage: the plan removes guaranteed fleeing, adds real hit-chance attacks with configurable damage, adds configurable morale pressure after landed hits, adds configurable fallback defense values, keeps the buff until next turn, avoids forced misses, and preserves existing IDs/settings.
- Placeholder scan: no placeholders are intentionally left.
- Type consistency: setting keys are consistent across settings, active-skill consumers, validator assertions, and README documentation.
