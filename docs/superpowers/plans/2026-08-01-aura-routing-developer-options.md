# Aura Routing Developer Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in developer options to `mod_aura_routing` so in-game Aura Routing testing is faster without installing a version-locked bro editor or modifying `mod_legends`.

**Architecture:** Add a new MSU settings page named `Developer Options`, then add small runtime helpers inside the Aura loader. Developer tools are fully disabled by default; when enabled, they run idempotently through existing roster/UI data flow and use direct skill granting today, plus Legends background `addPerk()` when the Legends-compatible perk definition exists.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU ModSettings, optional Legends background perk API, PowerShell static tests, `modbb` build flow.

## Global Constraints

- Do not modify `mod_legends` or `data_001`.
- Implement the feature only in `mod_aura_routing`.
- Developer options must default to disabled.
- Do not add a hotkey in this first version; avoid keybind conflicts with Legends and other UI mods.
- All developer actions must log through `::AuraRouting.Mod.Debug.printLog(...)`.
- Developer actions must be idempotent for a single game session.
- Preserve normal vanilla and Legends behavior when developer options are disabled.
- Build with `modbb`; do not manually create the zip.
- Document runtime assumptions in `README.md` and a developer doc.

---

## File Structure

- Create: `mod_aura_routing/docs/developer_options.md`
  - Documents how to enable and use the developer options.
  - Documents that the first implementation applies when roster UI data is converted, not through a hotkey.

- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_settings.nut`
  - Adds the `Developer Options` settings page.
  - Adds `EnableDeveloperOptions`, `DeveloperGrantAuraOnLoad`, and `DeveloperGrantResourcesOnLoad`.

- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
  - Enables debug logging when developer tools are active.
  - Adds `::AuraRouting.DeveloperSession` session state.
  - Adds helper functions for developer gating, resource granting, Aura granting, and Legends background-tree insertion.
  - Calls the helper from the existing `convertEntityToUIData` hook.

- Modify: `mod_aura_routing/README.md`
  - Adds a short user-facing section for developer options.

- Create: `mod_aura_routing/tools/test_aura_routing_developer_options.ps1`
  - Static regression test for settings IDs, helper names, gating, docs, and no hotkey addition.

---

### Task 1: Document The Developer Options Contract

**Files:**
- Create: `mod_aura_routing/docs/developer_options.md`
- Modify: `mod_aura_routing/README.md`

**Interfaces:**
- Consumes: approved design from conversation.
- Produces: documented setting IDs and runtime assumptions consumed by Tasks 2-4.

- [ ] **Step 1: Create the developer options doc**

Create `mod_aura_routing/docs/developer_options.md` with:

```markdown
# Developer Options

Developer options are opt-in test helpers for faster in-game validation of Aura Routing. They are disabled by default and are not intended for normal campaigns.

## Settings

- `EnableDeveloperOptions`: master switch. When disabled, no developer action runs.
- `DeveloperGrantAuraOnLoad`: when enabled, roster characters receive the Aura Routing perk skill when their UI data is converted.
- `DeveloperGrantResourcesOnLoad`: when enabled, the current roster receives test XP and perk points, and the company receives crowns and supplies once per game session.

## Runtime Behavior

The first version does not add a hotkey. It applies through existing roster UI data conversion so it avoids keybind conflicts with Legends, Breditor, BBForge, and other UI-heavy mods.

In Legends games, if Aura Routing has already been registered as a real Legends perk definition, the developer helper also tries to add Aura to the character background tree through `background.addPerk(...)`. If that registration is not available yet, the helper grants the Aura Routing perk skill directly so combat testing remains possible.

## Safety Notes

These helpers mutate the active campaign state. Use them on disposable test saves. Keep the developer options disabled in normal campaigns.
```

- [ ] **Step 2: Add README section**

Append this section before `# Known Issue` in `README.md`:

```markdown
## Developer Options

Aura Routing includes disabled-by-default developer options for faster in-game testing. When enabled in Mod Settings, they can grant test resources and grant Aura Routing to roster characters as their UI data is converted. Use these only on disposable test saves.

See `docs/developer_options.md` for the exact setting IDs and runtime behavior.
```

- [ ] **Step 3: Verify docs contain the exact contract**

Run:

```powershell
rg -n "Developer Options|EnableDeveloperOptions|DeveloperGrantAuraOnLoad|DeveloperGrantResourcesOnLoad|disposable test saves|background\.addPerk" .\mod_aura_routing\README.md .\mod_aura_routing\docs\developer_options.md
```

Expected: all setting IDs and the Legends `background.addPerk` note are present.

---

### Task 2: Add MSU Developer Settings

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_settings.nut`
- Test: `mod_aura_routing/tools/test_aura_routing_developer_options.ps1`

**Interfaces:**
- Consumes: setting IDs documented in Task 1.
- Produces: MSU settings `EnableDeveloperOptions`, `DeveloperGrantAuraOnLoad`, and `DeveloperGrantResourcesOnLoad`.

- [ ] **Step 1: Write the failing static test**

Create `mod_aura_routing/tools/test_aura_routing_developer_options.ps1` with:

```powershell
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Settings = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_settings.nut") -Raw
$Loader = Get-Content (Join-Path $Root "scripts/!mods_preload/mod_aura_routing_loader.nut") -Raw
$Readme = Get-Content (Join-Path $Root "README.md") -Raw
$Docs = Get-Content (Join-Path $Root "docs/developer_options.md") -Raw

$RequiredSettings = @(
    'addPage("Developer Options")',
    'addBooleanSetting("EnableDeveloperOptions", false',
    'addBooleanSetting("DeveloperGrantAuraOnLoad", false',
    'addBooleanSetting("DeveloperGrantResourcesOnLoad", false'
)

foreach ($Needle in $RequiredSettings) {
    if ($Settings -notlike "*$Needle*") {
        throw "Missing developer setting token: $Needle"
    }
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
    if ($Loader -notlike "*$Needle*") {
        throw "Missing developer loader token: $Needle"
    }
}

if ($Loader -match 'addSQKeybind|addJSKeybind') {
    throw "Developer options must not add a hotkey in the first version."
}

foreach ($Needle in @('Developer Options', 'EnableDeveloperOptions', 'disposable test saves')) {
    if ($Readme -notlike "*$Needle*" -and $Docs -notlike "*$Needle*") {
        throw "Missing documentation token: $Needle"
    }
}

Write-Host "Aura Routing developer options static checks passed."
```

- [ ] **Step 2: Run the static test and verify it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_aura_routing\tools\test_aura_routing_developer_options.ps1
```

Expected: FAIL with `Missing developer setting token: addPage("Developer Options")`.

- [ ] **Step 3: Add the settings page**

In `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_settings.nut`, after:

```nut
	local fallback = ::AuraRouting.Mod.ModSettings.addPage("Fallback Defense");
```

add:

```nut
	local developer = ::AuraRouting.Mod.ModSettings.addPage("Developer Options");
```

At the end of `registerSettings()`, before the closing `}`, add:

```nut
	developer.addBooleanSetting(
		"EnableDeveloperOptions",
		false,
		"Enable Developer Options",
		"Enables Aura Routing developer helpers for disposable test saves."
	);

	developer.addBooleanSetting(
		"DeveloperGrantAuraOnLoad",
		false,
		"Grant Aura For Testing",
		"When developer options are enabled, grant Aura Routing to roster characters as their UI data is converted."
	);

	developer.addBooleanSetting(
		"DeveloperGrantResourcesOnLoad",
		false,
		"Grant Test Resources",
		"When developer options are enabled, grant test crowns, supplies, XP, and perk points once per game session."
	);
```

- [ ] **Step 4: Run the static test and verify settings pass**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_aura_routing\tools\test_aura_routing_developer_options.ps1
```

Expected: FAIL moves from missing setting tokens to missing loader tokens.

---

### Task 3: Add Developer Session State And Resource Granting

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
- Test: `mod_aura_routing/tools/test_aura_routing_developer_options.ps1`

**Interfaces:**
- Consumes: MSU settings from Task 2.
- Produces:
  - `::AuraRouting.DeveloperSession`
  - `isAuraRoutingDeveloperOptionsEnabled() -> bool`
  - `applyAuraRoutingDeveloperResourcesOnce() -> void`

- [ ] **Step 1: Add session state**

Inside the queued hook in `mod_aura_routing_loader.nut`, immediately after:

```nut
	local mod = ::AuraRouting.HookMod;
```

add:

```nut
	::AuraRouting.DeveloperSession <- {
		HasGrantedResources = false
	};
```

- [ ] **Step 2: Add the developer enable helper**

Below the session state, add:

```nut
	local function isAuraRoutingDeveloperOptionsEnabled()
	{
		return ::AuraRouting.Mod.ModSettings.getSetting("EnableDeveloperOptions").getValue();
	}
```

- [ ] **Step 3: Enable debug logs when developer tools are enabled**

Replace the current hard-coded debug disable call:

```nut
	::AuraRouting.Mod.Debug.disable()
```

with:

```nut
	if (isAuraRoutingDeveloperOptionsEnabled())
	{
		::AuraRouting.Mod.Debug.enable();
		::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] developer options enabled");
	}
	else
	{
		::AuraRouting.Mod.Debug.disable();
	}
```

Implementation note: because `isAuraRoutingDeveloperOptionsEnabled()` must exist before this call, place the session state and helper before the debug enable/disable block. Keep `::AuraRouting.registerSettings();` before the helper because the helper reads settings.

- [ ] **Step 4: Add resource granting helper**

Below `isAuraRoutingDeveloperOptionsEnabled()`, add:

```nut
	local function applyAuraRoutingDeveloperResourcesOnce()
	{
		if (!isAuraRoutingDeveloperOptionsEnabled())
		{
			return;
		}

		if (!::AuraRouting.Mod.ModSettings.getSetting("DeveloperGrantResourcesOnLoad").getValue())
		{
			return;
		}

		if (::AuraRouting.DeveloperSession.HasGrantedResources)
		{
			return;
		}

		::AuraRouting.DeveloperSession.HasGrantedResources = true;

		::World.Assets.addMoney(50000);
		::World.Assets.addArmorParts(200);
		::World.Assets.addMedicine(200);
		::World.Assets.addAmmo(200);

		local roster = ::World.getPlayerRoster().getAll();
		foreach (bro in roster)
		{
			if (bro == null)
			{
				continue;
			}

			bro.addXP(10000, false);
			bro.m.PerkPoints += 10;
			bro.updateLevel();
		}

		::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] granted test resources and roster XP/perk points");
	}
```

- [ ] **Step 5: Call resource helper from UI conversion**

Inside the existing `q.convertEntityToUIData` wrapper, after:

```nut
			local result = __original(_entity, _activeEntity);
```

add:

```nut
			applyAuraRoutingDeveloperResourcesOnce();
```

- [ ] **Step 6: Run the static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_aura_routing\tools\test_aura_routing_developer_options.ps1
```

Expected: FAIL moves to missing Aura grant helper tokens.

---

### Task 4: Add Aura Granting For Fast Combat And Legends Tree Testing

**Files:**
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
- Test: `mod_aura_routing/tools/test_aura_routing_developer_options.ps1`

**Interfaces:**
- Consumes:
  - `isAuraRoutingDeveloperOptionsEnabled() -> bool`
  - `DeveloperGrantAuraOnLoad`
- Produces:
  - `findAuraRoutingLegendsPerkDefNumber() -> int|null`
  - `grantAuraRoutingForDeveloperTest(_entity) -> void`

- [ ] **Step 1: Add Legends perk definition lookup helper**

Below `applyAuraRoutingDeveloperResourcesOnce()`, add:

```nut
	local function findAuraRoutingLegendsPerkDefNumber()
	{
		if (!::Hooks.hasMod("mod_legends"))
		{
			return null;
		}

		if (!("PerkDefObjects" in ::Const.Perks) || ::Const.Perks.PerkDefObjects == null)
		{
			return null;
		}

		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.aura_routing")
			{
				return i;
			}
		}

		return null;
	}
```

- [ ] **Step 2: Add Aura grant helper**

Below `findAuraRoutingLegendsPerkDefNumber()`, add:

```nut
	local function grantAuraRoutingForDeveloperTest( _entity )
	{
		if (!isAuraRoutingDeveloperOptionsEnabled())
		{
			return;
		}

		if (!::AuraRouting.Mod.ModSettings.getSetting("DeveloperGrantAuraOnLoad").getValue())
		{
			return;
		}

		if (_entity == null || !_entity.isPlayerControlled())
		{
			return;
		}

		local skills = _entity.getSkills();
		if (skills == null)
		{
			return;
		}

		local background = _entity.getBackground();
		if (::Hooks.hasMod("mod_legends") && background != null)
		{
			local auraPerkDef = findAuraRoutingLegendsPerkDefNumber();
			if (auraPerkDef != null && "addPerk" in background && "getPerk" in background)
			{
				if (background.getPerk("perk.aura_routing") == null)
				{
					local row = ::AuraRouting.Mod.ModSettings.getSetting("PerkLevel").getValue() - 1;
					background.addPerk(auraPerkDef, row < 0 ? 0 : row, true);
					::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] added Aura Routing to Legends background tree for " + _entity.getName());
				}
			}
			else
			{
				::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] Legends Aura perk definition not available; granting skill directly for " + _entity.getName());
			}
		}

		if (!skills.hasSkill("perk.aura_routing"))
		{
			skills.add(::new("scripts/skills/perks/aura_routing_perk"));
			::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] granted Aura Routing perk skill to " + _entity.getName());
		}
	}
```

- [ ] **Step 3: Call Aura grant helper from UI conversion**

Inside the existing `q.convertEntityToUIData` wrapper, immediately after:

```nut
			applyAuraRoutingDeveloperResourcesOnce();
```

add:

```nut
			grantAuraRoutingForDeveloperTest(_entity);
```

- [ ] **Step 4: Run the static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_aura_routing\tools\test_aura_routing_developer_options.ps1
```

Expected: PASS with `Aura Routing developer options static checks passed.`

---

### Task 5: Static Verification, Build, And In-Game Test

**Files:**
- Read: `C:\Users\gujar\Documents\Battle Brothers\log.html`
- Generated by build: `mod_aura_routing/build/` or configured `modbb` output

**Interfaces:**
- Consumes: Tasks 1-4.
- Produces: built mod and in-game evidence that developer options speed up testing.

- [ ] **Step 1: Run targeted grep checks**

Run:

```powershell
rg -n "Developer Options|EnableDeveloperOptions|DeveloperGrantAuraOnLoad|DeveloperGrantResourcesOnLoad|AuraRouting\\]\\[Developer\\]|findAuraRoutingLegendsPerkDefNumber|grantAuraRoutingForDeveloperTest|applyAuraRoutingDeveloperResourcesOnce" .\mod_aura_routing
```

Expected: settings, docs, and loader helper tokens are visible.

- [ ] **Step 2: Run the dedicated static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\mod_aura_routing\tools\test_aura_routing_developer_options.ps1
```

Expected: PASS with `Aura Routing developer options static checks passed.`

- [ ] **Step 3: Run existing test suite**

Run from `mod_aura_routing`:

```powershell
python -m unittest discover -s tests
```

Expected: PASS.

- [ ] **Step 4: Build with modbb**

Run from `mod_aura_routing`:

```powershell
modbb --config .\mod_config.json
```

Expected: build completes without tracebacks and writes the configured output.

- [ ] **Step 5: In-game verification without Legends**

Start a disposable non-Legends campaign with Aura Routing installed. In Mod Settings, enable:

```text
Enable Developer Options = true
Grant Aura For Testing = true
Grant Test Resources = true
```

Open the character screen.

Expected:

```text
Roster bros receive extra XP/perk points once for the game session.
Roster bros receive Aura Routing perk skill.
Aura Routing active skill appears on affected bros.
No repeated +50000 crowns grant occurs when switching between bros.
```

- [ ] **Step 6: In-game verification with Legends**

Start a disposable Legends campaign with Aura Routing installed. Enable the same settings and open the character screen.

Expected before the Legends perk-tree compatibility patch:

```text
Roster bros receive the Aura Routing perk skill directly.
Log may state that the Legends Aura perk definition is not available.
The character screen does not crash.
```

Expected after the Legends perk-tree compatibility patch:

```text
Aura Routing is also added to the Legends background tree via background.addPerk(...).
The Aura perk appears in the configured perk row.
The character screen does not crash.
```

- [ ] **Step 7: Check logs**

Run:

```powershell
$html = Get-Content "$env:USERPROFILE\Documents\Battle Brothers\log.html" -Raw
$rows = $html -split '<div class="row '
$rows |
    Where-Object { $_ -match 'AuraRouting|Aura Routing|Developer|TypeError|Script Error|Exception' } |
    Select-Object -Last 100 |
    ForEach-Object {
        ($_ -replace '<[^>]+>', ' ' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&amp;', '&' -replace '\s+', ' ').Trim()
    }
```

Expected:

```text
[AuraRouting][Developer] developer options enabled
[AuraRouting][Developer] granted test resources and roster XP/perk points
[AuraRouting][Developer] granted Aura Routing perk skill to ...
No TypeError, Script Error, or Exception from Aura Routing developer helpers.
```

---

## Self-Review

- Spec coverage: The plan adds a disabled-by-default developer settings page, documents the feature first, avoids hotkeys, keeps all changes inside `mod_aura_routing`, provides fast Aura/resource grants, handles Legends through `background.addPerk()` only when the perk definition exists, and uses `modbb`.
- Placeholder scan: No unresolved placeholder markers or unspecified test commands remain.
- Type consistency: Setting IDs are consistent across docs, settings, loader helpers, static test, and verification steps. Helper names are consistent: `isAuraRoutingDeveloperOptionsEnabled`, `applyAuraRoutingDeveloperResourcesOnce`, `findAuraRoutingLegendsPerkDefNumber`, and `grantAuraRoutingForDeveloperTest`.
