# Aura Routing Fallback Rage Eyes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a subtle pulsing `zombie_rage_eyes` battlefield visual whenever Aura Routing fallback defense is applied, and remove it when the fallback effect ends.

**Architecture:** Keep fallback mechanics in `effects.aura_routing_evasion`; add only visual lifecycle behavior to that existing effect. Use vanilla's `zombie_rage_eyes` brush on the actor's `permanent_injury_4` sprite, matching `data_001/scripts/skills/effects/possessing_undead_effect.nut`, instead of using the full-body `miniboss` layer. After the initial fade-in, run a lightweight scheduled alpha pulse until the effect is removed, then stop the pulse and restore the previous `permanent_injury_4` sprite state so temporary rage eyes do not permanently overwrite missing-eye or injury visuals.

**Tech Stack:** Battle Brothers Squirrel scripts, vanilla brush `zombie_rage_eyes`, existing Aura Routing effect script, PowerShell static layout validator, `modbb` build flow.

## Global Constraints

- Do not modify `data_001`; it is reference only.
- Do not change Aura Routing targeting, hit chance, damage, morale, charges, AP, fatigue, or fallback defense values.
- Do not change effect IDs; keep `effects.aura_routing_evasion` for save compatibility.
- Use vanilla brush ID exactly: `zombie_rage_eyes`.
- Use the human actor sprite layer `permanent_injury_4`, because vanilla humans define it and vanilla possession uses it for `zombie_rage_eyes`.
- Make the eyes continuously dim/pulse while fallback defense is active; do not leave the brush as a static red-eye overlay.
- Do not use `aura_body_glow_v2` or the `miniboss` sprite layer for the fallback persistent visual.
- Add targeted debug logs through `::AuraRouting.Mod.Debug.printLog(...)` for visual apply, unavailable sprite, unavailable brush, and cleanup.
- Use `modbb` for build verification; do not manually build ZIPs.

---

## File Structure

- Modify: `scripts/skills/effects/aura_routing_evasion_effect.nut`
  - Owns fallback defense bonuses and should own the temporary fallback visual lifecycle.
- Modify: `tools/test_aura_routing_layout.ps1`
  - Guards against accidentally reintroducing the rejected body-glow/miniboss fallback visual and verifies the new rage-eyes hooks.
- No change: `scripts/skills/actives/aura_routing_skill.nut`
  - It already creates `effects.aura_routing_evasion` after fallback applies. The active skill should not know how the visual is rendered.
- Optional modify: `README.md`
  - Only update if implementation discovers a runtime limitation that players need to know, such as `permanent_injury_4` conflict behavior.

---

### Task 1: Add Static Regression Guard For Rage-Eyes Visual

**Files:**
- Modify: `tools/test_aura_routing_layout.ps1`

**Interfaces:**
- Consumes: existing `Require-Token` and `Forbid-Token` helpers.
- Produces: validator expectations that Task 2 must satisfy.

- [ ] **Step 1: Add failing validator tokens**

In `tools/test_aura_routing_layout.ps1`, extend the existing `Require-Token 'scripts/skills/effects/aura_routing_evasion_effect.nut' @(...)` block with these exact tokens:

```powershell
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
    'Aura Fallback Eyes: removed'
```

Extend the existing `Forbid-Token 'scripts/skills/actives/aura_routing_skill.nut' @(...)` block only if it does not already forbid the rejected fallback body visual:

```powershell
    'actor.setSpriteOffset("miniboss"',
    'glow.setBrush("aura_body_glow_v2");'
```

Add a second `Forbid-Token` block for the fallback effect file:

```powershell
Forbid-Token 'scripts/skills/effects/aura_routing_evasion_effect.nut' @(
    'actor.setSpriteOffset("miniboss"',
    'glow.setBrush("aura_body_glow_v2");',
    'function pulseTick('
)
```

- [ ] **Step 2: Run validator and confirm RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected: fails with a missing token from `aura_routing_evasion_effect.nut`, such as:

```text
Missing token in scripts/skills/effects/aura_routing_evasion_effect.nut: function showFallbackEyes()
```

- [ ] **Step 3: Commit validator red state only if working in small commits**

```bash
git add tools/test_aura_routing_layout.ps1
git commit -m "test: guard aura fallback rage eyes visual"
```

Skip this commit if the branch is using one final commit.

---

### Task 2: Implement Temporary Zombie Rage Eyes On Fallback Effect

**Files:**
- Modify: `scripts/skills/effects/aura_routing_evasion_effect.nut`

**Interfaces:**
- Consumes: `effects.aura_routing_evasion` added by `aura_routing_skill.applyFallbackEvasion(_user, _affectedCount)`.
- Produces:
  - `function showFallbackEyes()` -> applies visual if possible.
  - `function hideFallbackEyes()` -> restores previous sprite state.
  - `onAdded()` -> starts visual.
  - `onRemoved()` and `onCombatFinished()` -> clean up visual.

- [ ] **Step 1: Extend effect state**

In `scripts/skills/effects/aura_routing_evasion_effect.nut`, change the `m` table from:

```nut
m = {
    MeleeDefenseBonus = 0,
    RangedDefenseBonus = 0
},
```

to:

```nut
m = {
    MeleeDefenseBonus = 0,
    RangedDefenseBonus = 0,
    IsFallbackEyesVisible = false,
    PreviousPermanentInjury4Brush = null,
    PreviousPermanentInjury4Visible = false,
    PreviousPermanentInjury4Alpha = 255,
    PulseToken = 0,
    PulseStartMs = 0,
    PulsePeriodMs = 1200,
    PulseMinAlpha = 90,
    PulseMaxAlpha = 255,
    PulseTickMs = 60
},
```

- [ ] **Step 2: Add helper to save current sprite state**

Add this function after `create()`:

```nut
function rememberPermanentInjury4State( _sprite )
{
    this.m.PreviousPermanentInjury4Visible = _sprite.Visible;
    this.m.PreviousPermanentInjury4Alpha = _sprite.Alpha;

    local brush = _sprite.getBrush();
    this.m.PreviousPermanentInjury4Brush = brush == null ? null : brush.Name;
}
```

- [ ] **Step 3: Add helper to show rage eyes**

Add this function after `rememberPermanentInjury4State(...)`:

```nut
function showFallbackEyes()
{
    local actor = this.getContainer().getActor();
    if (actor == null) return;

    if (!actor.hasSprite("permanent_injury_4"))
    {
        ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: missing permanent_injury_4 sprite");
        return;
    }

    if (!this.doesBrushExist("zombie_rage_eyes"))
    {
        ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: missing zombie_rage_eyes brush");
        return;
    }

    local sprite = actor.getSprite("permanent_injury_4");
    this.rememberPermanentInjury4State(sprite);

    ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: applying zombie_rage_eyes");
    sprite.Visible = true;
    sprite.setBrush("zombie_rage_eyes");

    if (actor.isHiddenToPlayer())
    {
        sprite.Alpha = 255;
    }
    else
    {
        sprite.Alpha = 0;
        sprite.fadeIn(1500);
    }

    this.m.IsFallbackEyesVisible = true;
    actor.setDirty(true);
    this.startFallbackEyesPulse();
}
```

- [ ] **Step 4: Add helper to pulse the eyes continuously**

Add these functions after `showFallbackEyes()`:

```nut
function fallbackEyesPulseTick( _ctx )
{
    if (this.m.PulseToken != _ctx.token) return;
    if (!this.m.IsFallbackEyesVisible) return;
    if (this.getContainer() == null) return;

    local actor = this.getContainer().getActor();
    if (actor == null || !actor.isAlive() || !actor.hasSprite("permanent_injury_4")) return;

    local sprite = actor.getSprite("permanent_injury_4");
    if (!sprite.Visible) return;

    local elapsed = ::Time.getRealTime() * 1000.0 - this.m.PulseStartMs;
    local cycles = elapsed / this.m.PulsePeriodMs.tofloat();
    local phase = cycles - ::Math.floor(cycles);
    local tri = phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0;
    local smooth = tri * tri * (3.0 - 2.0 * tri);
    local alpha = this.m.PulseMinAlpha + (this.m.PulseMaxAlpha - this.m.PulseMinAlpha) * smooth;
    sprite.Alpha = alpha.tointeger();

    ::Time.scheduleEvent(::TimeUnit.Real, this.m.PulseTickMs, this.fallbackEyesPulseTick.bindenv(this), _ctx);
}

function startFallbackEyesPulse()
{
    this.m.PulseToken = this.m.PulseToken + 1;
    this.m.PulseStartMs = ::Time.getRealTime() * 1000.0;
    ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: pulse started");

    local ctx = {
        token = this.m.PulseToken
    };
    ::Time.scheduleEvent(::TimeUnit.Real, this.m.PulseTickMs, this.fallbackEyesPulseTick.bindenv(this), ctx);
}

function stopFallbackEyesPulse()
{
    this.m.PulseToken = this.m.PulseToken + 1;
    ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: pulse stopped");
}
```

Implementation note: token invalidation is required because scheduled events cannot be unscheduled directly. Incrementing `PulseToken` makes any already-scheduled tick return without touching the sprite.

- [ ] **Step 5: Add helper to hide and restore rage eyes**

Add this function after `stopFallbackEyesPulse()`:

```nut
function hideFallbackEyes()
{
    if (!this.m.IsFallbackEyesVisible) return;
    if (this.getContainer() == null) return;
    this.stopFallbackEyesPulse();

    local actor = this.getContainer().getActor();
    if (actor == null || !actor.hasSprite("permanent_injury_4")) return;

    local sprite = actor.getSprite("permanent_injury_4");

    if (this.m.PreviousPermanentInjury4Brush != null)
    {
        sprite.setBrush(this.m.PreviousPermanentInjury4Brush);
    }
    else
    {
        sprite.resetBrush();
    }

    sprite.Alpha = this.m.PreviousPermanentInjury4Alpha;
    sprite.Visible = this.m.PreviousPermanentInjury4Visible;

    if (!this.m.PreviousPermanentInjury4Visible && !actor.isHiddenToPlayer())
    {
        sprite.setBrush("zombie_rage_eyes");
        sprite.Alpha = 255;
        sprite.Visible = true;
        sprite.fadeOutAndHide(1500);
    }

    this.m.IsFallbackEyesVisible = false;
    ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: removed");
    actor.setDirty(true);
}
```

Implementation note: this restores a previous visible permanent-injury brush immediately. If there was no previous visible sprite, it allows a fade-out of the rage eyes. That avoids permanently hiding a missing-eye visual.

- [ ] **Step 6: Wire lifecycle hooks**

After `onUpdate(_properties)`, add:

```nut
function onAdded()
{
    this.showFallbackEyes();
}
```

Keep existing `onTurnStart()` exactly as the mechanical expiration point:

```nut
function onTurnStart()
{
    this.removeSelf();
}
```

Add cleanup hooks after `onTurnStart()`:

```nut
function onRemoved()
{
    this.stopFallbackEyesPulse();
    this.hideFallbackEyes();
}

function onCombatFinished()
{
    this.stopFallbackEyesPulse();
    this.hideFallbackEyes();
}
```

- [ ] **Step 7: Run validator and confirm GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
```

Expected:

```text
Aura Routing layout validation passed.
```

- [ ] **Step 8: Commit implementation only if working in small commits**

```bash
git add scripts/skills/effects/aura_routing_evasion_effect.nut tools/test_aura_routing_layout.ps1
git commit -m "feat: show rage eyes for aura fallback defense"
```

Skip this commit if the branch is using one final commit.

---

### Task 3: Build And Runtime Verification

**Files:**
- Read: `C:\Users\gujar\Documents\Battle Brothers\log.html`
- Build output: use a temporary `--game-data-dir`; do not write into Steam's protected install directory during verification.

**Interfaces:**
- Consumes: completed Tasks 1 and 2.
- Produces: verified mod ZIP and runtime checklist.

- [ ] **Step 1: Run static checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_aura_routing_layout.ps1
git diff --check
rg -n "aura_body_glow_v2|miniboss|pulseTick|zombie_rage_eyes|permanent_injury_4" scripts\skills\effects\aura_routing_evasion_effect.nut tools\test_aura_routing_layout.ps1
```

Expected:

```text
Aura Routing layout validation passed.
```

`git diff --check` must exit `0`. `rg` must show `zombie_rage_eyes` and `permanent_injury_4` in the fallback effect, and must not show `aura_body_glow_v2`, `miniboss`, or `pulseTick` in the fallback effect.

- [ ] **Step 2: Run local build**

Run:

```powershell
$out = Join-Path $env:TEMP ("aura_routing_verify_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $out | Out-Null
modbb --game-data-dir $out
Write-Host "VERIFY_OUTPUT=$out"
```

Expected:

```text
Building Battle Brothers Mod Aura Routing ...
Built brush: aura_routing_effect.brush
Deployed mod_aura_routing.zip to ...
Game launch not requested; skipping.
```

- [ ] **Step 3: In-game fallback cases**

Use the built mod in game and trigger Aura Routing fallback defense:

```text
Case A: Aura Routing affects 0 enemies with fallback defense value > 0.
Case B: Aura Routing affects 1 enemy with fallback defense value > 0.
Case C: Aura Routing affects 2 enemies with fallback defense value > 0.
Case D: Aura Routing affects enough enemies to skip fallback defense.
```

Expected:

```text
Cases A-C: caster gets fallback defense status and visible pulsing rage eyes.
Cases A-C: rage eyes continuously dim and brighten until the caster's next turn starts.
Cases A-C: rage eyes are removed when effects.aura_routing_evasion is removed.
Case D: no fallback defense status and no rage eyes.
```

- [ ] **Step 4: Check log.html**

After runtime testing, inspect:

```powershell
Select-String -Path 'C:\Users\gujar\Documents\Battle Brothers\log.html' -Pattern 'Aura Fallback Eyes|zombie_rage_eyes|permanent_injury_4|aura_routing_evasion|Error|Exception|Unable to open file' | Select-Object -Last 80
```

Expected:

```text
[AuraRouting] Aura Fallback Eyes: applying zombie_rage_eyes
[AuraRouting] Aura Fallback Eyes: pulse started
[AuraRouting] Aura Fallback Eyes: pulse stopped
[AuraRouting] Aura Fallback Eyes: removed
```

No red IO/UI missing-file errors for `zombie_rage_eyes`. No Squirrel errors from `aura_routing_evasion_effect.nut`.

Acceptable warning path:

```text
[AuraRouting] Aura Fallback Eyes: missing permanent_injury_4 sprite
```

This is acceptable only if the actor type does not expose the vanilla human `permanent_injury_4` layer. It should not happen for normal player brothers.

- [ ] **Step 5: Decide whether README needs an update**

If runtime testing shows a visible limitation, add this short note to `README.md` under the relevant Aura Routing section:

```markdown
- Fallback defense uses the vanilla `zombie_rage_eyes` sprite on the actor's `permanent_injury_4` layer as a temporary pulsing battlefield cue. It restores the previous sprite state when the fallback effect ends.
```

If runtime testing shows no visible limitation, skip the README change.

---

## Manual Review Checklist

- [ ] Fallback defense values still come from `NoAffected*`, `OneAffected*`, and `TwoAffected*` settings.
- [ ] `effects.aura_routing_evasion` ID is unchanged.
- [ ] Active skill mechanics are unchanged.
- [ ] Rejected fallback body visual is not present in `aura_routing_evasion_effect.nut`.
- [ ] `zombie_rage_eyes` only appears as a temporary pulsing visual cue.
- [ ] Pulse stops when `effects.aura_routing_evasion` is removed.
- [ ] `permanent_injury_4` previous brush, visibility, and alpha are restored.
- [ ] No missing asset red logs are introduced.

## Self-Review

- Spec coverage: the plan replaces the bad full-body visual with pulsing `zombie_rage_eyes`, keeps fallback behavior unchanged, and includes logging plus runtime verification.
- Placeholder scan: no placeholder steps remain.
- Type consistency: helper names are consistent across validator tokens and implementation steps.
