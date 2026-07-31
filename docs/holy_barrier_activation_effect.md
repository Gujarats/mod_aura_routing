# Holy Barrier Activation Effect

## Goal

Make the generated holy barrier asset available to `mod_aura_routing` and show it on the caster when the Aura Routing active skill is used.

## Asset Source

Source directory:

`C:\Users\gujar\Documents\Codex\2026-07-31\can\outputs`

Confirmed source files:

- `holy_barrier_spritesheet_4x2.png`
- `holy_barrier_frames\holy_barrier_01.png` through `holy_barrier_08.png`

Each separate frame is `320x320`.

## Implementation Plan

Use the existing `aura_routing_effect` custom brush package instead of adding a separate brush package. Copy the eight frame PNGs into the brush source directory and register them as `aura_holy_barrier_01` through `aura_holy_barrier_08`.

For the first in-game test, spawn one visible barrier sprite on the caster tile when Aura Routing activates. This keeps the effect scoped to the caster and avoids changing targeting, hit, morale, or fallback defense behavior.

## Verification

Update the existing layout validation script so it confirms:

- the metadata contains the holy barrier sprite IDs;
- the activation skill checks for `aura_holy_barrier_06`;
- the activation skill spawns `aura_holy_barrier_06` on the caster tile.
