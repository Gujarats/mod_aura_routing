# Legends-Compatible Aura Perk Tree Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Aura Routing permanently available in Legends character perk trees without replacing Legends-generated trees or modifying `mod_legends`.

**Architecture:** Legends builds the authoritative perk tree on each background through `character_background.buildPerkTree()`, storing rows in `m.CustomPerkTree`, UI objects in `m.PerkTree`, and lookup state in `m.PerkTreeMap`. Aura Routing will queue after Legends, register Aura as a real Legends-compatible perk definition, then wrap `buildPerkTree()` and call `background.addPerk()` after the original build. Legends UI and unlock code will then use the normal `result.perkTree` and `background.getPerk()` paths.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU settings, Legends background perk tree API, Coherent UI JavaScript, `modbb` build flow, PowerShell static verification.

## Global Constraints

- Do not modify `mod_legends` or `data_001`.
- Implement the compatibility patch only in `mod_aura_routing`.
- Do not replace Legends `result.perkTree` with a tree built from `::Const.Perks.Perks`.
- Add optional Modern Hooks load ordering with `">mod_legends"`; do not add `require("mod_legends")`.
- Gate Legends-specific behavior with `::Hooks.hasMod("mod_legends")`.
- Register Aura as a real perk definition after Legends loads, because Legends resets `::Const.Perks.PerkDefObjects`.
- Add Aura through `background.addPerk()` after `buildPerkTree()` completes.
- Avoid duplicate `perk.aura_routing` entries.
- Preserve vanilla/non-Legends behavior.
- Build with `modbb`; do not manually create the zip.
- Document the save dependency: Legends saves with Aura in `m.CustomPerkTree` require `mod_aura_routing`.

---

## File Structure

- Modify: `mod_aura_routing/scripts/config/z_aura.nut`
  - Keep vanilla Aura registration.
  - Add `Const = "AuraRouting"` and string keys needed by Legends-compatible registration.

- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
  - Queue after Legends when installed.
  - Register Aura into `::Const.Perks.PerkDefObjects` after Legends loads.
  - Hook `scripts/skills/backgrounds/character_background`.
  - Add Aura to finished Legends background trees through `background.addPerk()`.
  - Keep current UI data injection only for non-Legends games.

- Modify: `mod_aura_routing/ui/mods/aura_routing.js`
  - Skip Aura's custom UI tree replacement when Legends supplies `perkTree`.
  - Keep null guard around `this.mPerkTree.auraRoutingTree`.

- Modify: `mod_aura_routing/README.md`
  - Document Legends compatibility and save dependency.

- Reference only: `mod_aura_routing/docs/legends_perk_system_compatibility.md`
  - Source-backed guide for why this plan uses permanent background integration.

---

### Task 1: Register Aura With A Legends-Compatible Perk Definition

**Files:**
- Modify: `mod_aura_routing/scripts/config/z_aura.nut`
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`

**Interfaces:**
- Consumes: `::Const.Perks.addPerkDefObjects()` when Legends is installed
- Produces: `::Legends.Perk.AuraRouting` and `::Const.Perks.PerkDefs.AuraRouting` after Legends loads

- [ ] **Step 1: Add `Const` to the Aura perk object in `z_aura.nut`**

Change the Aura perk definition to include:

```nut
Const = "AuraRouting"
```

Expected object:

```nut
addPerk({
    ID = "perk.aura_routing"
    Script = "scripts/skills/perks/aura_routing_perk"
    Name = "Aura Routing"
    Tooltip = "Unlocks the Aura Routing active skill."
    Icon = "aura/aura_routing_perk.png"
    IconDisabled = "aura/aura_routing_perk_sw.png"
    Const = "AuraRouting"
    Row = 4
})
```

- [ ] **Step 2: Add Legends registration helper inside the queued hook body in `mod_aura_routing_loader.nut`**

Place this after `local mod = ::AuraRouting.HookMod;`:

```nut
	local function registerAuraRoutingPerkDefForLegends()
	{
		if (!::Hooks.hasMod("mod_legends") || !("addPerkDefObjects" in ::Const.Perks))
		{
			return null;
		}

		if (!("AuraRouting" in ::Const.Strings.PerkName))
		{
			::Const.Strings.PerkName.AuraRouting <- "Aura Routing";
		}

		if (!("AuraRouting" in ::Const.Strings.PerkDescription))
		{
			::Const.Strings.PerkDescription.AuraRouting <- "Unlocks the Aura Routing active skill.";
		}

		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef.ID == "perk.aura_routing")
			{
				::Legends.Perk.AuraRouting <- i;
				::Const.Perks.PerkDefs.AuraRouting <- i;
				return i;
			}
		}

		::Legends.Perk.AuraRouting <- null;
		::Const.Perks.addPerkDefObjects([
			{
				ID = "perk.aura_routing",
				Script = "scripts/skills/perks/aura_routing_perk",
				Name = "Aura Routing",
				Tooltip = "Unlocks the Aura Routing active skill.",
				Icon = "aura/aura_routing_perk.png",
				IconDisabled = "aura/aura_routing_perk_sw.png",
				Const = "AuraRouting"
			}
		]);

		return ::Legends.Perk.AuraRouting;
	}
```

- [ ] **Step 3: Call the helper once and store the result**

Below the helper:

```nut
	local auraRoutingLegendsPerkDef = registerAuraRoutingPerkDefForLegends();
```

- [ ] **Step 4: Static verification**

Run:

```powershell
rg -n "Const = \"AuraRouting\"|registerAuraRoutingPerkDefForLegends|addPerkDefObjects|Legends\\.Perk\\.AuraRouting|PerkName\\.AuraRouting|PerkDescription\\.AuraRouting" .\mod_aura_routing\scripts
```

Expected: all tokens are present.

---

### Task 2: Queue Aura After Legends Optionally

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`

**Interfaces:**
- Consumes: Modern Hooks queue ordering
- Produces: Aura loader runs after Legends when Legends is installed, but does not require Legends

- [ ] **Step 1: Update queue expression**

Replace:

```nut
::AuraRouting.HookMod.queue(">mod_msu", ">mod_necro", function()
```

With:

```nut
::AuraRouting.HookMod.queue(">mod_msu", ">mod_legends", ">mod_necro", function()
```

- [ ] **Step 2: Verify no hard Legends dependency**

Run:

```powershell
rg -n "HookMod\\.require|HookMod\\.queue" .\mod_aura_routing\scripts\!mods_preload\mod_aura_routing_loader.nut
```

Expected: `require()` only mentions `mod_msu`; queue includes `>mod_legends`.

---

### Task 3: Add Aura After Legends Builds Each Background Tree

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`

**Interfaces:**
- Consumes: `auraRoutingLegendsPerkDef`, Legends `character_background.addPerk()`, MSU `PerkLevel` setting
- Produces: every eligible Legends background tree contains `perk.aura_routing`

- [ ] **Step 1: Add row helper**

Place below `auraRoutingLegendsPerkDef`:

```nut
	local function getAuraRoutingConfiguredRow()
	{
		local row = ::AuraRouting.Mod.ModSettings.getSetting("PerkLevel").getValue() - 1;
		return row < 0 ? 0 : row;
	}
```

- [ ] **Step 2: Add background-tree hook**

Place before `mod.hook("scripts/ui/global/data_helper", function(q)`:

```nut
	mod.hook("scripts/skills/backgrounds/character_background", function(q)
	{
		q.buildPerkTree = @(__original) function()
		{
			local attributes = __original();

			if (::Hooks.hasMod("mod_legends")
				&& auraRoutingLegendsPerkDef != null
				&& this.m.PerkTreeMap != null
				&& this.getPerk("perk.aura_routing") == null)
			{
				this.addPerk(auraRoutingLegendsPerkDef, getAuraRoutingConfiguredRow(), true);
			}

			return attributes;
		}
	});
```

- [ ] **Step 3: Static verification**

Run:

```powershell
rg -n "scripts/skills/backgrounds/character_background|q\\.buildPerkTree|this\\.addPerk\\(auraRoutingLegendsPerkDef|getAuraRoutingConfiguredRow|this\\.getPerk\\(\"perk\\.aura_routing\"\\)" .\mod_aura_routing\scripts\!mods_preload\mod_aura_routing_loader.nut
```

Expected: the hook wraps `buildPerkTree()` and calls `addPerk()` only after original build.

---

### Task 4: Keep Aura UI Override Out Of Legends

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
- Modify: `mod_aura_routing/ui/mods/aura_routing.js`

**Interfaces:**
- Consumes: Legends path from Task 3
- Produces: current `aura_routing_perkTree` fallback remains for vanilla/non-Legends only

- [ ] **Step 1: Guard current UI tree injection**

In `convertEntityToUIData`, before building `local perks = ::Const.Perks.Perks.map(...)`, add:

```nut
						if (::Hooks.hasMod("mod_legends"))
						{
							return result;
						}
```

This prevents Aura from producing `result.aura_routing_perkTree` in Legends games.

- [ ] **Step 2: Null-guard JS tagging**

In `ui/mods/aura_routing.js`, change:

```javascript
this.mPerkTree.auraRoutingTree = true;
```

to:

```javascript
if (this.mPerkTree)
{
	this.mPerkTree.auraRoutingTree = true;
}
```

- [ ] **Step 3: Run JavaScript syntax check**

Run:

```powershell
node --check .\mod_aura_routing\ui\mods\aura_routing.js
```

Expected: no output and exit code `0`.

---

### Task 5: Document Save Dependency

**Files:**
- Modify: `mod_aura_routing/README.md`
- Modify: `mod_aura_routing/docs/legends_perk_system_compatibility.md`

**Interfaces:**
- Consumes: permanent background-tree integration decision
- Produces: user-facing and developer-facing documentation of the save dependency

- [ ] **Step 1: Add README compatibility note**

Add a short note:

```markdown
## Legends Compatibility

When Legends is installed, Aura Routing is added permanently to each eligible character's Legends perk tree after the background tree is built. Saves where characters have Aura Routing in their perk tree should continue to be played with `mod_aura_routing` installed.
```

- [ ] **Step 2: Verify guide decision remains Strategy A**

Run:

```powershell
rg -n "Decision For `mod_aura_routing`|Strategy A|buildPerkTree|save compatibility" .\mod_aura_routing\docs\legends_perk_system_compatibility.md .\mod_aura_routing\README.md
```

Expected: docs clearly state permanent integration and save dependency.

---

### Task 6: Build With `modbb`

**Files:**
- Generated by build: `mod_aura_routing/build/` or configured modbb output

**Interfaces:**
- Consumes: patched source from Tasks 1-5
- Produces: rebuilt Aura Routing mod through the supported CLI

- [ ] **Step 1: Run static grep checks**

Run:

```powershell
rg -n "Hooks\\.hasMod\\(\"mod_legends\"\\)|AuraRouting|buildPerkTree|aura_routing_perkTree" .\mod_aura_routing\scripts .\mod_aura_routing\ui .\mod_aura_routing\README.md
```

Expected: Legends path and vanilla fallback are both visible.

- [ ] **Step 2: Build with modbb**

Run from `mod_aura_routing`:

```powershell
modbb --config .\mod_config.json
```

Expected: build completes without tracebacks and writes output through the configured `modbb` build flow.

---

### Task 7: In-Game Verification

**Files:**
- Read: `%USERPROFILE%\Documents\Battle Brothers\log.html`

**Interfaces:**
- Consumes: installed build from Task 6
- Produces: evidence that Aura is visible and unlockable in Legends without replacing Legends trees

- [ ] **Step 1: Start Battle Brothers with Legends and Aura Routing installed**

Expected log includes:

```text
Modern Hooks registered Aura Routing
Modern Hooks registered Legends
```

- [ ] **Step 2: Open several character screens**

Expected:

```text
Character screen opens.
Existing Legends perk groups remain visible.
Aura Routing appears on the configured row.
No `this.mPerkTree.auraRoutingTree` null error appears.
```

- [ ] **Step 3: Unlock Aura Routing**

Expected:

```text
Aura Routing unlocks through normal Legends backend flow.
Perk point is spent.
Aura Routing active skill is granted.
```

- [ ] **Step 4: Check logs**

Run:

```powershell
$html = Get-Content "$env:USERPROFILE\Documents\Battle Brothers\log.html" -Raw
$rows = $html -split '<div class="row '
$rows |
    Where-Object { $_ -match 'aura_routing|TypeError|Script Error|Exception|buildPerkTree|unlockPerk' } |
    Select-Object -Last 80 |
    ForEach-Object {
        ($_ -replace '<[^>]+>', ' ' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&amp;', '&' -replace '\s+', ' ').Trim()
    }
```

Expected: no UI crash and no failed unlock script error.

---

## Self-Review

- Spec coverage: The plan follows the selected permanent Legends integration, adds Aura after `buildPerkTree()`, avoids replacing `result.perkTree`, preserves vanilla fallback, uses optional `>mod_legends` ordering, and builds with `modbb`.
- Placeholder scan: No `TBD`, `TODO`, or undefined implementation steps remain.
- Type consistency: `auraRoutingLegendsPerkDef`, `::Legends.Perk.AuraRouting`, `background.addPerk()`, `background.getPerk()`, and `result.aura_routing_perkTree` are used consistently.
