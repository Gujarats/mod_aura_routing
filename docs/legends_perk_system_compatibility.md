# Legends Perk System Compatibility Guide

This guide summarizes how `mod_legends` builds, exposes, and unlocks perks, based on the local Legends source. It is intended for `mod_aura_routing` compatibility work and for future mods that need to add perks without replacing Legends perk trees.

## Source Files Reviewed

- `mod_legends/scripts/!mods_preload/register_legends.nut`
- `mod_legends/mod_legends/load.nut`
- `mod_legends/mod_legends/!!config/perks_defs.nut`
- `mod_legends/mod_legends/helper/skills/perks.nut`
- `mod_legends/mod_legends/config/perks_tree.nut`
- `mod_legends/mod_legends/config/z_perks_tree_*.nut`
- `mod_legends/mod_legends/hooks/skills/backgrounds/character_background.nut`
- `mod_legends/mod_legends/hooks/ui/global/data_helper.nut`
- `mod_legends/mod_legends/hooks/entity/tactical/player.nut`
- `mod_legends/ui/screens/character/modules/character_screen_right_panel/character_screen_perks_module.js`
- `mod_legends/scripts/skills/perks/perk_legend_adaptive.nut`

## Load Order

Legends registers itself as `mod_legends` in `scripts/!mods_preload/register_legends.nut`, then includes `mod_legends/load.nut`.

`load.nut` loads folders in this order:

1. `mod_legends/!!config`
2. `mod_legends/!config/outfit`
3. `mod_legends/!config`
4. `mod_legends/config`
5. `mod_legends/helper`
6. `mod_legends/system`
7. `mod_legends/register`
8. `mod_legends/hooks`

For an optional compatibility patch, use Modern Hooks ordering:

```nut
::AuraRouting.HookMod.queue(">mod_msu", ">mod_legends", ">mod_necro", function()
```

Do not use `require("mod_legends")` unless Aura should become unusable without Legends. The local patterns in `mod_bandages_enhanced` and `mod_mentor_rookie` use `">mod_legends"` as an optional ordering edge.

At runtime, guard Legends-specific behavior with:

```nut
local hasLegends = ::Hooks.hasMod("mod_legends");
```

## Perk Definitions

Legends resets and owns:

```nut
::Const.Perks.PerkDefObjects <- [];
::Const.Perks.PerkDefs <- {};
```

in `mod_legends/mod_legends/!!config/perks_defs.nut`.

It registers perk definitions through:

```nut
::Const.Perks.addPerkDefObjects(perkDefObjects, _container = ::Legends.Perk)
```

That function:

- appends definitions into `::Const.Perks.PerkDefObjects`
- writes numeric constants into `::Const.Perks.PerkDefs`
- writes numeric constants into `::Legends.Perk` or a supplied container
- writes `::Const.Perks.LookupMap[perkDefObject.ID]`

Legends perk scripts usually call:

```nut
::Legends.Perks.onCreate(this, ::Legends.Perk.SomePerk);
```

from `create()`. This fills ID, name, description, icons, type, and skill order from the registered perk definition.

### Compatibility Note For Aura

Current Aura registration only pushes `perk.aura_routing` into `::Const.Perks.Aura` and `::Const.Perks.LookupMap`. It does not register a stable numeric entry in `::Const.Perks.PerkDefObjects` / `::Const.Perks.PerkDefs`.

That is enough for a UI-only vanilla-style tree object, but not enough for Legends APIs such as:

```nut
background.addPerk(_perkDefNumber, row)
::Legends.Perks.getID(_perkDefNumber)
```

Any Legends-compatible implementation that uses Legends background APIs must first make Aura addressable as a real perk definition.

## Tree Definitions And Dynamic Generation

Legends does not use one global, fixed perk tree for every brother.

`mod_legends/mod_legends/config/perks_tree.nut` defines:

- `BuildCustomPerkTree(_custom)`
- `GetDynamicPerkTree(_mins, _map, _allowRearrangement = true)`
- `MergeDynamicPerkTree(_tree, _map)`
- `PerksTreeTemplate`

The active tree pools are defined across `z_perks_tree_*.nut` files. In this local source, active group pools include:

- `WeaponTrees`
- `DefenseTrees`
- `TraitsTrees`
- `EnemyTrees`
- `ClassTrees`
- `ProfessionTrees`
- `MagicTrees`

The default background dynamic minimums are in `character_background.nut`:

```nut
Weapon = 8
Defense = 2
Traits = 7
Enemy = 1
Class = 1
Profession = 1
Magic = 1
```

Several of those categories also use chance fields, so not every category is guaranteed for every generated tree.

## Authoritative Background State

The authoritative Legends perk tree lives on the character background:

```nut
m.CustomPerkTree
m.PerkTree
m.PerkTreeMap
```

Important methods in `character_background.nut`:

- `getPerkTree()` returns `m.PerkTree` when built.
- `getPerk(_perk)` looks up by ID in `m.PerkTreeMap`.
- `addPerk(_perkDefNumber, _preferredRow, _isRefundable = true)` adds to `m.PerkTree`, `m.CustomPerkTree`, and `m.PerkTreeMap`.
- `addPerkGroup(_Tree)` adds a complete group by calling `addPerk()`.
- `removePerk(_perkDefNumber)` removes from `m.PerkTree`, `m.CustomPerkTree`, and `m.PerkTreeMap`.
- `buildPerkTree()` creates `m.CustomPerkTree`, `m.PerkTree`, and `m.PerkTreeMap`.
- `rebuildPerkTree(_tree)` rebuilds those fields and merges dynamic pieces.

This is the key rule:

> In Legends, displaying a perk in UI is not enough. Unlocking depends on the background's `m.PerkTreeMap`.

## UI Export

Legends exports the final built background tree in `mod_legends/mod_legends/hooks/ui/global/data_helper.nut`:

```nut
result.perkTree = _entity.getBackground().getPerkTree();
```

The hire screen also receives:

```nut
result.perkTree <- _entity.getBackground().getPerkTree();
```

The Legends character screen JS reads `_brother[CharacterScreenIdentifier.Perk.Tree]`, which is `perkTree`, and calls:

```javascript
this.setupPerkTree(_brother[CharacterScreenIdentifier.Perk.Tree]);
```

Legends intentionally leaves `onPerkTreeLoaded()` as an empty callback. Mods that rely on vanilla `onPerkTreeLoaded(null, tree)` can crash or do nothing under Legends.

## Unlock Validation

Backend unlock validation is in `mod_legends/mod_legends/hooks/entity/tactical/player.nut`.

`unlockPerk(_id)` does:

```nut
local perk = this.getBackground().getPerk(_id);
if (perk == null)
{
    return false;
}
```

`isPerkUnlockable(_id)` also calls:

```nut
local perk = this.getBackground().getPerk(_id);
```

Therefore, a compatibility patch that only injects Aura into UI data can show the icon but still fail to unlock.

## Tree Mutation After Background Generation

Perk trees are not only determined by background generation. Legends can mutate them later.

`perk_legend_adaptive.nut` is the clearest example:

- When `LegendAdaptive` is added, it checks equipped mainhand first.
- Then equipped offhand.
- Then unarmed.
- Then armor weight.
- Then random trait fallback.
- It calls `actor.getBackground().addPerkGroup(...)`.

Other scripts and events also call `addPerkGroup()` or `rebuildPerkTree()`.

Compatibility patches should therefore consume or modify the final background tree, not try to predict every initial background combination.

## Save Compatibility

`character_background.nut` serializes `m.CustomPerkTree` as rows of numeric perk IDs:

```nut
_out.writeU16(this.m.CustomPerkTree[i][j]);
```

On load, it reads those IDs back and calls `buildPerkTree()`.

This matters for submods:

- Permanent `background.addPerk()` writes the mod perk into `m.CustomPerkTree`.
- That makes the perk visible and unlockable through normal Legends logic.
- It also means a save can contain the submod's numeric perk ID.
- Removing the submod later can leave saved perk trees referencing missing or shifted perk IDs.

For a perk-granting submod, this may be acceptable because unlocked skills also depend on the submod's script. But it must be documented as a save compatibility tradeoff.

## Compatibility Strategies

### Strategy A: Permanent Background Integration

Register Aura as a real perk definition, then add it to each eligible brother's background:

```nut
background.addPerk(::AuraRouting.Perk.AuraRouting, row);
result.perkTree = background.getPerkTree();
```

Pros:

- Uses Legends' normal `getPerk()`, `isPerkUnlockable()`, and `unlockPerk()` paths.
- UI and backend agree.
- No special unlock hook needed.

Cons:

- Mutates `m.CustomPerkTree`.
- Persists Aura into saves.
- Removing Aura later can be unsafe for saves that received the perk.
- If run from `convertEntityToUIData`, it may add Aura to many brothers simply by viewing them.

Use this only if Aura should become a permanent perk option for every eligible brother once the mod is installed.

### Strategy B: Transient UI Plus Dedicated Unlock Hook

Keep Aura out of `m.CustomPerkTree`. Instead:

1. Register Aura as a real perk definition.
2. Clone `result.perkTree` for UI and append Aura to the clone.
3. Hook `player.unlockPerk(_id)` for `perk.aura_routing`.
4. Hook `player.isPerkUnlockable(_id)` for `perk.aura_routing`.
5. On unlock, grant the Aura perk skill directly and spend the perk point.

Pros:

- Does not mutate Legends background trees.
- Lower risk of save tree corruption if Aura is later removed.
- Closer to current Aura behavior, which injects a visible perk option rather than altering background templates.

Cons:

- Must exactly mirror enough of Legends' unlock behavior.
- More code paths to maintain.
- Perk plan/right-click behavior may need separate handling if planning Aura matters.

This is likely safer if Aura should be an overlay mod rather than a permanent Legends tree modifier.

### Strategy C: Add A Legends Perk Group

Register Aura as a real perk definition and define an Aura-specific perk group, then add that group through `addPerkGroup()`.

Pros:

- Aligns with Legends' group model.
- Useful if Aura later becomes a multi-perk feature.

Cons:

- Same persistence risk as Strategy A.
- More work than needed for one perk.

## Decision For `mod_aura_routing`

Do not replace `result.perkTree` with a tree built from `::Const.Perks.Perks`. That discards the Legends-generated tree.

The selected design is Strategy A: Aura should become a permanent Legends perk-tree option for eligible characters.

The patch should not add Aura from `convertEntityToUIData()`, because opening a UI screen is the wrong time to mutate persistent character data. Instead, patch after Legends builds each background's tree:

```nut
background.buildPerkTree();
background.addPerk(auraPerkDef, configuredRow);
```

In practice this means hooking `scripts/skills/backgrounds/character_background` and wrapping `buildPerkTree()`. After the original Legends build finishes, Aura can add `perk.aura_routing` through `background.addPerk()`, so both `result.perkTree` and `background.getPerk("perk.aura_routing")` agree.

Important implementation notes:

- Aura must be registered as a real entry in `::Const.Perks.PerkDefObjects` after Legends loads, not only as `::Const.Perks.LookupMap["perk.aura_routing"]`.
- The Aura perk definition needs a `Const` field and matching `::Const.Strings.PerkName` / `::Const.Strings.PerkDescription` entries, because Legends afterHooks inspect perk definitions by `perk.Const`.
- The save compatibility tradeoff is accepted for this mod: saves where Aura has been added to `m.CustomPerkTree` should continue to load with `mod_aura_routing` installed.
- Do not modify `mod_legends`; implement the patch in `mod_aura_routing`.

## Validation Checklist For A Patch

- `mod_aura_routing` queues after `mod_legends` optionally with `">mod_legends"`.
- Runtime code checks `::Hooks.hasMod("mod_legends")`.
- Aura is registered as a real perk definition in the active perk registry.
- Aura is added after `character_background.buildPerkTree()` through `background.addPerk()`.
- Legends UI path uses `result.perkTree` from `background.getPerkTree()`.
- Legends UI path never replaces `perkTree` with a vanilla/global tree.
- The displayed Aura perk can be unlocked through backend Squirrel logic.
- The patch does not modify `mod_legends` source.
- The README or docs state any save compatibility assumption.
