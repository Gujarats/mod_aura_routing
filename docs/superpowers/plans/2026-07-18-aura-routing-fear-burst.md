# Aura Routing Fear Burst Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a red/orange, outward-moving, lingering dust particle burst to every enemy successfully affected by Aura Routing.

**Architecture:** Keep the effect self-contained in `aura_routing_skill.nut`. A helper will construct one directional `sand_dust_01` particle effect from the caster to a target tile, and the existing valid-enemy loop will call it immediately before shaking and fleeing that enemy.

**Tech Stack:** Battle Brothers Squirrel scripts; vanilla `sand_dust_01` particle brush; static validation with PowerShell.

## Global Constraints

- Do not change Aura Routing targeting, morale, AP/fatigue cost, charge consumption, or its existing `aura_body_glow_v2` effect.
- Use the existing vanilla particle brush ID exactly: `sand_dust_01`.
- Spawn particles only for enemies that pass the existing alive and non-allied check.
- Do not silently swallow errors; log missing brushes or particle-spawn errors through `::AuraRouting.Mod.Debug.printLog`.

---

### Task 1: Add and validate the per-target fear-burst helper

**Files:**
- Modify: `scripts/skills/actives/aura_routing_skill.nut`
- Test: inline PowerShell static validation command

**Interfaces:**
- Consumes: `_user.getTile()` and a valid target tile.
- Produces: `spawnFearBurst(_originTile, _targetTile)`, which attempts one directional particle burst and returns no value.

- [ ] **Step 1: Write the failing static validation command**

Run this from the `mod_aura_routing` repository root:

```powershell
$p = 'scripts/skills/actives/aura_routing_skill.nut'
$s = Get-Content -Raw $p
$patterns = @(
  'function spawnFearBurst\( _originTile, _targetTile \)',
  '"sand_dust_01"',
  'this\.spawnFearBurst\(_user\.getTile\(\), tile\);'
)
($patterns | ForEach-Object { $s -match $_ }) -notcontains $false
```

- [ ] **Step 2: Run the validation and verify it fails**

Run:

```powershell
$p = 'scripts/skills/actives/aura_routing_skill.nut'
$s = Get-Content -Raw $p
$patterns = @('function spawnFearBurst\( _originTile, _targetTile \)', '"sand_dust_01"', 'this\.spawnFearBurst\(_user\.getTile\(\), tile\);')
($patterns | ForEach-Object { $s -match $_ }) -notcontains $false
```

Expected: `False`, because no `spawnFearBurst` helper exists yet.

- [ ] **Step 3: Add the helper and invoke it for each affected enemy**

Add this method before `onTargetSelected`:

```nut
function spawnFearBurst( _originTile, _targetTile )
{
    if (!this.doesBrushExist("sand_dust_01"))
    {
        ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Missing particle brush: sand_dust_01");
        return;
    }

    local direction = _originTile.getDirectionTo(_targetTile);
    local directionVectors = [
        this.createVec(0.0, -1.0), this.createVec(0.85, -0.5),
        this.createVec(0.85, 0.5), this.createVec(0.0, 1.0),
        this.createVec(-0.85, 0.5), this.createVec(-0.85, -0.5)
    ];
    local burstDirection = directionVectors[direction];
    local effect = {
        Delay = 0,
        Quantity = 16,
        LifeTimeQuantity = 16,
        SpawnRate = 400,
        Brushes = ["sand_dust_01"],
        Stages = [
            {
                LifeTimeMin = 0.1, LifeTimeMax = 0.2,
                ColorMin = this.createColor("e65c1a00"), ColorMax = this.createColor("ffb34700"),
                ScaleMin = 0.5, ScaleMax = 0.75,
                RotationMin = 0, RotationMax = 359,
                VelocityMin = 70, VelocityMax = 115,
                DirectionMin = burstDirection, DirectionMax = burstDirection,
                SpawnOffsetMin = this.createVec(-25, -15), SpawnOffsetMax = this.createVec(25, 20)
            },
            {
                LifeTimeMin = 0.75, LifeTimeMax = 1.0,
                ColorMin = this.createColor("e65c1acc"), ColorMax = this.createColor("ffb347aa"),
                ScaleMin = 0.55, ScaleMax = 0.9,
                VelocityMin = 15, VelocityMax = 35,
                ForceMin = this.createVec(0, 0), ForceMax = this.createVec(0, 0)
            },
            {
                LifeTimeMin = 0.1, LifeTimeMax = 0.2,
                ColorMin = this.createColor("e65c1a00"), ColorMax = this.createColor("ffb34700"),
                ScaleMin = 0.75, ScaleMax = 1.0,
                VelocityMin = 0, VelocityMax = 0,
                ForceMin = this.createVec(0, -100), ForceMax = this.createVec(0, -100)
            }
        ]
    };

    try
    {
        this.Tactical.spawnParticleEffect(false, effect.Brushes, _targetTile, effect.Delay, effect.Quantity, effect.LifeTimeQuantity, effect.SpawnRate, effect.Stages, this.createVec(0, 70));
    }
    catch (e)
    {
        ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Fear burst failed: " + e);
    }
}
```

In the existing valid-enemy block, immediately before `getShaker().shake`, add:

```nut
this.spawnFearBurst(_user.getTile(), tile);
```

- [ ] **Step 4: Run static validation and inspect the diff**

Run:

```powershell
$p = 'scripts/skills/actives/aura_routing_skill.nut'
$s = Get-Content -Raw $p
$patterns = @('function spawnFearBurst\( _originTile, _targetTile \)', '"sand_dust_01"', 'this\.spawnFearBurst\(_user\.getTile\(\), tile\);')
($patterns | ForEach-Object { $s -match $_ }) -notcontains $false
git diff --check
git diff -- $p
```

Expected: `True`, no whitespace errors, and a helper plus one call in the valid-enemy block.

- [ ] **Step 5: Perform in-game verification and commit**

Use Aura Routing against one, two, and three enemies, then repeat while facing each hex direction. Confirm only affected enemies receive the burst, the dust travels away from the caster, and the cloud lingers about one second.

After successful in-game verification:

```powershell
git add scripts/skills/actives/aura_routing_skill.nut
git commit -m "feat: add Aura Routing fear burst"
```
