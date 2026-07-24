# Aura Routing Morale Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show Aura Routing's morale drop chance while the player has Aura Routing selected and hovers a highlighted enemy target.

**Architecture:** Keep the calculation inside `aura_routing_skill.nut`, because the skill already owns morale eligibility, settings, target arc logic, and hit behavior. Hook actor tooltips from the existing Modern Hooks loader so that base game tooltip flow still handles hit chance, while Aura Routing appends morale-specific preview lines only for this skill.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU settings, existing PowerShell static validation.

## Global Constraints

- Do not modify `data_001`; use it only as the source reference for morale math.
- Keep existing skill ID `actives.aura_routing`.
- Keep the base hit chance tooltip intact; append morale preview below it.
- Morale preview is shown only while Aura Routing is selected and the hovered tile contains an enemy that is in the selected arc.
- The preview must distinguish attack hit chance from morale drop chance on hit.
- The preview must show immune targets clearly.
- Static validation is acceptable here because the project already uses token-based PowerShell checks instead of an in-game test harness.

---

## File Structure

- Modify `mod_aura_routing/scripts/skills/actives/aura_routing_skill.nut`
  - Add deterministic helper methods that mirror `data_001/scripts/entity/tactical/actor.nut::checkMorale`.
  - Add tooltip line generation for one target.
  - Add arc membership check so tooltip text only appears for highlighted Aura Routing targets.
- Modify `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
  - Hook `scripts/entity/tactical/actor.getTooltip(_targetedWithSkill)`.
  - Append Aura Routing morale preview lines after the base tooltip is produced.
- Modify `mod_aura_routing/tools/test_aura_routing_layout.ps1`
  - Require the new helper methods and hook tokens.
  - Guard against misleading text like "total chance" unless implemented explicitly.
- Modify `mod_aura_routing/README.md`
  - Document that hovering a highlighted target shows morale drop chance on hit.

---

### Task 1: Add Morale Chance Calculation To Aura Routing Skill

**Files:**
- Modify: `mod_aura_routing/scripts/skills/actives/aura_routing_skill.nut`
- Test: `mod_aura_routing/tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes:
  - `canAffectMorale(_entity)` already in `aura_routing_skill.nut`
  - `collectArcTiles(_user, _targetTile)` already in `aura_routing_skill.nut`
  - MSU settings `MoraleResolvePenalty`, `MoraleDropSteps`, `AllowFleeingOnAlreadyWavering`
- Produces:
  - `function isTileInSelectedArc( _user, _targetTile ) -> bool`
  - `function getMoraleChangeForPreview( _entity ) -> integer`
  - `function getMoraleResistChancePct( _user, _entity ) -> integer`
  - `function getMoraleDropChanceOnHitPct( _user, _entity ) -> integer`
  - `function getAuraRoutingTargetTooltip( _targetEntity ) -> array<table>`

- [ ] **Step 1: Add failing static validation tokens**

Modify `mod_aura_routing/tools/test_aura_routing_layout.ps1`.

In the `Require-Token 'scripts/skills/actives/aura_routing_skill.nut' @(` block, add these tokens:

```powershell
    'function isTileInSelectedArc( _user, _targetTile )',
    'function getMoraleChangeForPreview( _entity )',
    'function getMoraleResistChancePct( _user, _entity )',
    'function getMoraleDropChanceOnHitPct( _user, _entity )',
    'function getAuraRoutingTargetTooltip( _targetEntity )',
    'local score = bravery + difficulty - numOpponentsAdjacent * this.Const.Morale.OpponentsAdjacentMult + numAlliesAdjacent * this.Const.Morale.AlliesAdjacentMult - threatBonus;',
    'local resistChance = baseResist + (100 - baseResist) * rerollChance * baseResist / 10000;',
    '"Morale drop on hit: [color=" + this.Const.UI.Color.PositiveValue + "]" + dropChance + "%[/color]"',
```

Add this token to the `Forbid-Token 'scripts/skills/actives/aura_routing_skill.nut' @(` block:

```powershell
    'Total morale drop chance'
```

- [ ] **Step 2: Run validation to verify it fails**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: FAIL with missing token errors for the new Aura Routing preview methods.

- [ ] **Step 3: Add arc membership and morale change helpers**

In `mod_aura_routing/scripts/skills/actives/aura_routing_skill.nut`, insert this code after `collectArcTiles` and before `canAffectMorale`:

```nut
	function isTileInSelectedArc( _user, _targetTile )
	{
		if (_user == null || _targetTile == null) return false;
		if (!("State" in this.Tactical) || this.Tactical.State == null) return false;

		local selectedTile = this.Tactical.State.getSelectedSkillTargetTile();
		if (selectedTile == null) return false;

		local tiles = this.collectArcTiles(_user, selectedTile);
		foreach (tile in tiles)
		{
			if (tile.ID == _targetTile.ID) return true;
		}

		return false;
	}

	function getMoraleChangeForPreview( _entity )
	{
		if (_entity == null) return 0;

		local before = _entity.getMoraleState();
		local steps = ::AuraRouting.Mod.ModSettings.getSetting("MoraleDropSteps").getValue();
		local change = -steps;

		if (before == this.Const.MoraleState.Wavering
			&& ::AuraRouting.Mod.ModSettings.getSetting("AllowFleeingOnAlreadyWavering").getValue())
		{
			change = this.Const.MoraleState.Fleeing - before;
		}
		else if (before + change < this.Const.MoraleState.Fleeing)
		{
			change = this.Const.MoraleState.Fleeing - before;
		}

		return change;
	}
```

- [ ] **Step 4: Add morale resistance calculation**

In `mod_aura_routing/scripts/skills/actives/aura_routing_skill.nut`, insert this code after `getMoraleChangeForPreview` and before `canAffectMorale`:

```nut
	function getMoraleResistChancePct( _user, _entity )
	{
		if (_user == null || _entity == null) return 0;
		if (!this.canAffectMorale(_entity)) return 100;

		local change = this.getMoraleChangeForPreview(_entity);
		if (change >= 0) return 100;

		local properties = _entity.getCurrentProperties();
		local difficulty = -::AuraRouting.Mod.ModSettings.getSetting("MoraleResolvePenalty").getValue();
		difficulty = difficulty * properties.MoraleEffectMult;

		local bravery = (_entity.getBravery() + properties.MoraleCheckBravery[this.Const.MoraleCheckType.MentalAttack]) * properties.MoraleCheckBraveryMult[this.Const.MoraleCheckType.MentalAttack];
		if (bravery > 500) return 100;

		local myTile = _entity.getTile();
		local numOpponentsAdjacent = 0;
		local numAlliesAdjacent = 0;
		local threatBonus = 0;

		for (local i = 0; i != 6; i = ++i)
		{
			if (!myTile.hasNextTile(i)) continue;

			local tile = myTile.getNextTile(i);
			if (!tile.IsOccupiedByActor) continue;

			local neighbor = tile.getEntity();
			if (neighbor == null || neighbor.getMoraleState() == this.Const.MoraleState.Fleeing) continue;

			if (neighbor.isAlliedWith(_entity))
			{
				numAlliesAdjacent = ++numAlliesAdjacent;
			}
			else
			{
				numOpponentsAdjacent = ++numOpponentsAdjacent;
				threatBonus = threatBonus + neighbor.getCurrentProperties().Threat;
			}
		}

		local score = bravery + difficulty - numOpponentsAdjacent * this.Const.Morale.OpponentsAdjacentMult + numAlliesAdjacent * this.Const.Morale.AlliesAdjacentMult - threatBonus;
		local baseResist = this.Math.max(0, this.Math.min(95, score)).tointeger();
		local rerollChance = this.Math.max(0, this.Math.min(100, properties.RerollMoraleChance)).tointeger();
		local resistChance = baseResist + (100 - baseResist) * rerollChance * baseResist / 10000;

		return this.Math.max(0, this.Math.min(100, resistChance)).tointeger();
	}

	function getMoraleDropChanceOnHitPct( _user, _entity )
	{
		if (_user == null || _entity == null) return 0;
		if (!this.canAffectMorale(_entity)) return 0;

		local change = this.getMoraleChangeForPreview(_entity);
		if (change >= 0) return 0;

		return 100 - this.getMoraleResistChancePct(_user, _entity);
	}
```

- [ ] **Step 5: Add target tooltip lines**

In `mod_aura_routing/scripts/skills/actives/aura_routing_skill.nut`, insert this code after `getMoraleDropChanceOnHitPct` and before `canAffectMorale`:

```nut
	function getAuraRoutingTargetTooltip( _targetEntity )
	{
		local ret = [];
		local user = this.m.Container.getActor();
		if (user == null || _targetEntity == null) return ret;
		if (!_targetEntity.isAlive() || _targetEntity.isAlliedWith(user)) return ret;
		if (!this.isTileInSelectedArc(user, _targetEntity.getTile())) return ret;

		if (!this.canAffectMorale(_targetEntity))
		{
			ret.push({
				id = 91001,
				type = "text",
				icon = "ui/icons/bravery.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Immune to Aura Routing morale drop[/color]"
			});
			return ret;
		}

		local dropChance = this.getMoraleDropChanceOnHitPct(user, _targetEntity);
		local resistChance = this.getMoraleResistChancePct(user, _targetEntity);
		local change = -this.getMoraleChangeForPreview(_targetEntity);

		ret.push({
			id = 91001,
			type = "text",
			icon = "ui/icons/bravery.png",
			text = "Morale drop on hit: [color=" + this.Const.UI.Color.PositiveValue + "]" + dropChance + "%[/color]"
		});
		ret.push({
			id = 91002,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Target Resolve: [color=" + this.Const.UI.Color.PositiveValue + "]" + _targetEntity.getBravery() + "[/color], resist chance: [color=" + this.Const.UI.Color.PositiveValue + "]" + resistChance + "%[/color], morale drop: [color=" + this.Const.UI.Color.NegativeValue + "]" + change + " step" + (change == 1 ? "" : "s") + "[/color]"
		});

		return ret;
	}
```

- [ ] **Step 6: Run validation to verify Task 1 passes after hook tokens still fail**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: If Task 2 tokens have not been added yet, failures should now be only for loader/README tokens added later. If only Task 1 tokens exist, expected result is PASS.

---

### Task 2: Hook Actor Tooltip While Aura Routing Is Selected

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
- Test: `mod_aura_routing/tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes:
  - `getAuraRoutingTargetTooltip(_targetEntity)` from Task 1
- Produces:
  - Actor tooltips append Aura Routing morale preview when `_targetedWithSkill.getID() == "actives.aura_routing"`

- [ ] **Step 1: Add failing static validation tokens**

Modify `mod_aura_routing/tools/test_aura_routing_layout.ps1`.

Add this new block after the existing loader-related checks:

```powershell
Require-Token 'scripts/!mods_preload/mod_aura_routing_loader.nut' @(
    'mod.hook("scripts/entity/tactical/actor", function(q)',
    'q.getTooltip = @(__original) function( _targetedWithSkill = null )',
    '_targetedWithSkill.getID() == "actives.aura_routing"',
    'local auraRoutingLines = _targetedWithSkill.getAuraRoutingTargetTooltip(this);',
    'tooltip.push(line);'
)
```

- [ ] **Step 2: Run validation to verify it fails**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: FAIL with missing loader hook tokens.

- [ ] **Step 3: Hook actor tooltip in the loader**

In `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`, inside the existing `::AuraRouting.HookMod.queue(">mod_msu", function() { ... })` block, add this hook after the existing `mod.hook("scripts/ui/global/data_helper", function(q) { ... });` block:

```nut
	mod.hook("scripts/entity/tactical/actor", function(q)
	{
		q.getTooltip = @(__original) function( _targetedWithSkill = null )
		{
			local tooltip = __original(_targetedWithSkill);

			if (_targetedWithSkill != null
				&& this.isKindOf(_targetedWithSkill, "skill")
				&& _targetedWithSkill.getID() == "actives.aura_routing"
				&& "getAuraRoutingTargetTooltip" in _targetedWithSkill)
			{
				local auraRoutingLines = _targetedWithSkill.getAuraRoutingTargetTooltip(this);
				foreach (line in auraRoutingLines)
				{
					tooltip.push(line);
				}
			}

			return tooltip;
		}
	});
```

- [ ] **Step 4: Run validation to verify Task 2 passes**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: PASS if Task 3 README tokens have not been added yet. If README tokens are already added, failure should only mention README.

---

### Task 3: Document Player-Facing Behavior

**Files:**
- Modify: `mod_aura_routing/README.md`
- Test: `mod_aura_routing/tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes:
  - Tooltip behavior from Task 2
- Produces:
  - README tells players that hovered highlighted targets show morale drop chance on hit.

- [ ] **Step 1: Add failing README validation token**

Modify `mod_aura_routing/tools/test_aura_routing_layout.ps1`.

In the `Require-Token 'README.md' @(` block, add:

```powershell
    'When Aura Routing is selected, hovering a highlighted enemy shows its morale drop chance on hit.',
```

- [ ] **Step 2: Run validation to verify it fails**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: FAIL with missing README token.

- [ ] **Step 3: Update README**

In `mod_aura_routing/README.md`, add this sentence near the Aura Routing gameplay description:

```markdown
When Aura Routing is selected, hovering a highlighted enemy shows its morale drop chance on hit.
```

- [ ] **Step 4: Run validation to verify Task 3 passes**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: PASS with:

```text
Aura Routing layout validation passed.
```

---

### Task 4: Build Package And Manual Smoke Test

**Files:**
- Generated: `mod_aura_routing/release/mod_aura_routing.zip` if the build script writes there

**Interfaces:**
- Consumes:
  - Completed code from Tasks 1-3
- Produces:
  - Built mod archive ready for in-game verification

- [ ] **Step 1: Run static validation**

Run from `mod_aura_routing`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected:

```text
Aura Routing layout validation passed.
```

- [ ] **Step 2: Build the mod**

Run from `mod_aura_routing`:

```powershell
python .\build_mod.py
```

Expected: build completes without Python tracebacks and writes the Aura Routing zip to the configured build/release output.

- [ ] **Step 3: In-game smoke test**

Install the built mod and start a tactical battle with a character that has Aura Routing.

Manual expected behavior:

```text
1. Select Aura Routing.
2. Hover a valid enemy in the 3-tile highlighted arc.
3. The normal hit chance line still appears.
4. A new line appears: "Morale drop on hit: X%".
5. A second line appears with target Resolve, resist chance, and morale drop steps.
6. Hover an enemy outside the highlighted arc: no Aura Routing morale preview appears.
7. Hover an undead or morale-immune enemy: "Immune to Aura Routing morale drop" appears if it is inside the highlighted arc.
8. Use the skill and verify behavior still follows existing hit/damage/morale/fallback logic.
```

---

## Self-Review

**Spec coverage:** The plan shows morale drop chance during highlighted Aura Routing targeting by adding calculation helpers, a selected-skill actor tooltip hook, validation tokens, README documentation, and a manual in-game smoke test.

**Placeholder scan:** No `TBD`, `TODO`, `implement later`, or unspecified test instructions remain.

**Type consistency:** The produced function names in Task 1 match the loader usage in Task 2: `getAuraRoutingTargetTooltip(_targetEntity)` is called on `_targetedWithSkill`.
