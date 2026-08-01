# Aura Routing Compatibility Module Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split Aura Routing's developer helpers and Legends compatibility logic out of the preload loader into focused modules without changing runtime behavior.

**Architecture:** The loader remains responsible for mod registration, settings registration, include ordering, UI asset registration, and shared hooks. Developer helpers move to `::AuraRouting.DeveloperOptions`. Legends-specific perk definition and background-tree hooks move to `::AuraRouting.Compatibility.Legends`. Each module defines functions at include time but only touches MSU, World, or Legends runtime state when called from the Modern Hooks queue.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU settings, Legends background perk API, PowerShell static regression tests, `modbb`.

## Global Constraints

- Do not modify `mod_legends`, `mod_reforged`, or `data_001`.
- Keep all code changes inside `mod_aura_routing`.
- Preserve current vanilla, Legends, Necro, and developer-option behavior.
- Do not add Reforged behavior in this refactor; only create a structure that can accept it later.
- Keep Legends optional: no `HookMod.require("mod_legends")`.
- Include module files only after `::AuraRouting` exists.
- Module files must not read MSU settings, `::World`, or `::Legends` at include time.
- Build with `modbb`; do not manually create the zip.

---

## File Structure

- Create: `mod_aura_routing/scripts/mods/aura_routing/developer_options.nut`
  - Owns developer session state, debug toggle, resource grants, and direct Aura grant testing.

- Create: `mod_aura_routing/scripts/mods/aura_routing/compatibility/legends_perk_tree_patch.nut`
  - Owns Legends perk definition registration, perk definition lookup, and `character_background.buildPerkTree()` hook.

- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
  - Includes the modules and calls their public `init()` / `registerHooks(mod)` APIs.
  - Keeps only shared UI fallback and actor tooltip hooks.

- Modify: `mod_aura_routing/tools/test_aura_routing_developer_options.ps1`
  - Verifies developer helper code lives in `developer_options.nut`.

- Modify: `mod_aura_routing/tools/test_aura_routing_legends_compat.ps1`
  - Verifies Legends helper code lives in `compatibility/legends_perk_tree_patch.nut`.

---

### Task 1: Add Refactor Static Tests

**Files:**
- Modify: `mod_aura_routing/tools/test_aura_routing_developer_options.ps1`
- Modify: `mod_aura_routing/tools/test_aura_routing_legends_compat.ps1`

**Interfaces:**
- Consumes: current static test scripts.
- Produces: failing tests that require extracted modules and loader include calls.

- [ ] **Step 1: Update developer-options static test**

Read `scripts/mods/aura_routing/developer_options.nut` into `$DeveloperOptions`. Assert it contains:

```powershell
'::AuraRouting.DeveloperOptions'
'function init()'
'function isEnabled()'
'function configureDebugLogging()'
'function applyResourcesOnce()'
'function grantAuraForTest( _entity )'
'DeveloperGrantAuraOnLoad'
'DeveloperGrantResourcesOnLoad'
'background.addPerk('
```

Assert loader contains:

```powershell
'::include("scripts/mods/aura_routing/developer_options");'
'::AuraRouting.DeveloperOptions.init();'
'::AuraRouting.DeveloperOptions.applyResourcesOnce();'
'::AuraRouting.DeveloperOptions.grantAuraForTest(_entity);'
```

- [ ] **Step 2: Update Legends static test**

Read `scripts/mods/aura_routing/compatibility/legends_perk_tree_patch.nut` into `$LegendsPatch`. Assert it contains:

```powershell
'::AuraRouting.Compatibility.Legends'
'function registerHooks( _mod )'
'function registerPerkDef()'
'function getAuraRoutingPerkDefNumber()'
'function addAuraToBackground( _background )'
'::Const.Perks.addPerkDefObjects'
'scripts/skills/backgrounds/character_background'
'q.buildPerkTree'
'_background.addPerk('
```

Assert loader contains:

```powershell
'::include("scripts/mods/aura_routing/compatibility/legends_perk_tree_patch");'
'::AuraRouting.Compatibility.Legends.registerHooks(mod);'
```

- [ ] **Step 3: Run tests and verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_developer_options.ps1
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_legends_compat.ps1
```

Expected: both fail because module files do not exist yet.

---

### Task 2: Extract Developer Options Module

**Files:**
- Create: `mod_aura_routing/scripts/mods/aura_routing/developer_options.nut`
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`

**Interfaces:**
- Produces:
  - `::AuraRouting.DeveloperOptions.init()`
  - `::AuraRouting.DeveloperOptions.isEnabled()`
  - `::AuraRouting.DeveloperOptions.configureDebugLogging()`
  - `::AuraRouting.DeveloperOptions.applyResourcesOnce()`
  - `::AuraRouting.DeveloperOptions.grantAuraForTest(_entity)`

- [ ] **Step 1: Create namespace module**

Add `developer_options.nut` with `::AuraRouting.DeveloperOptions <- { ... }`. The file must create only functions and constants at include time.

- [ ] **Step 2: Move developer helper code**

Move existing developer session, debug toggle, resource grant, and direct Aura grant logic from local functions into the namespace methods listed above.

- [ ] **Step 3: Update loader calls**

Add the include near the top of the loader after `::AuraRouting.HookMod.require(...)`, then replace local calls with:

```nut
::AuraRouting.DeveloperOptions.init();
::AuraRouting.DeveloperOptions.applyResourcesOnce();
::AuraRouting.DeveloperOptions.grantAuraForTest(_entity);
```

- [ ] **Step 4: Run developer test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_developer_options.ps1
```

Expected: developer options static checks pass.

---

### Task 3: Extract Legends Compatibility Module

**Files:**
- Create: `mod_aura_routing/scripts/mods/aura_routing/compatibility/legends_perk_tree_patch.nut`
- Modify: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`

**Interfaces:**
- Produces:
  - `::AuraRouting.Compatibility.Legends.registerHooks(_mod)`
  - `::AuraRouting.Compatibility.Legends.registerPerkDef()`
  - `::AuraRouting.Compatibility.Legends.getAuraRoutingPerkDefNumber()`
  - `::AuraRouting.Compatibility.Legends.addAuraToBackground(_background)`

- [ ] **Step 1: Create compatibility namespace**

Add `legends_perk_tree_patch.nut` with `::AuraRouting.Compatibility.Legends <- { ... }`. The file must not assume Legends exists until a method is called.

- [ ] **Step 2: Move Legends helper code**

Move perk definition registration, cached Aura perk-def lookup, and background-tree hook registration into the module.

- [ ] **Step 3: Update loader calls**

Add the include near the top of the loader after the developer module include, then call:

```nut
::AuraRouting.Compatibility.Legends.registerHooks(mod);
```

- [ ] **Step 4: Run Legends test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_legends_compat.ps1
```

Expected: Legends compatibility static checks pass.

---

### Task 4: Final Verification

**Files:**
- Read: `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`
- Generated by build: `mod_aura_routing/dist/mod_aura_routing.zip`

- [ ] **Step 1: Run targeted static checks**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_developer_options.ps1
powershell -ExecutionPolicy Bypass -File .\tools\test_aura_routing_legends_compat.ps1
node --check .\ui\mods\aura_routing.js
```

- [ ] **Step 2: Run existing tests**

Run:

```powershell
python -m unittest discover -s tests
```

- [ ] **Step 3: Build with modbb**

Run:

```powershell
modbb --config .\mod_config.json
```

Expected: local archive is produced in `dist`. If deployment to the Steam data directory fails because the game is running or the zip is locked, report that separately from source/build success.

## Self-Review

- Spec coverage: The plan separates developer and Legends code, keeps the loader as orchestration, and preserves optional Legends behavior.
- Placeholder scan: No placeholder implementation steps remain.
- Type consistency: Public module method names are consistent across tasks and tests.
