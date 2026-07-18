# Aura Routing fear-burst visual design

## Goal

Make Aura Routing clearly communicate its panic effect: each enemy forced into Fleeing receives a red/orange dust burst that appears to travel outward from the caster and leaves a short lingering cloud.

## Scope

The change affects only the visual feedback in `aura_routing_skill.nut`. It does not change targeting, morale logic, AP/fatigue cost, charges, or the existing body-glow effect.

## Visual sequence

1. The caster retains the existing `aura_body_glow_v2` red glow.
2. For every valid enemy that Aura Routing actually affects, the skill spawns a particle effect on that enemy's tile.
3. The first stage sends red/orange dust outward from the caster-facing side of the target tile, making the panic wave feel as though it travelled from caster to enemy.
4. The following stages slow and fade into a faint dust cloud lasting about one second.
5. The existing `getShaker().shake(entity, _user.getTile(), 4)` remains as the final impact cue.

## Particle asset and API

Use vanilla particle brush `sand_dust_01`, which is defined in `data_001/brushes/effects_0.brush` and atlas `data_001/gfx/effects_0.png`.

Call `Tactical.spawnParticleEffect` once per affected enemy. The particle stages follow the vanilla Throw Dirt structure:

- initial fast stage: 0.1--0.2 seconds, directional velocity, transparent-to-visible red/orange dust;
- lingering stage: roughly 0.75--1.0 seconds, lower velocity, fading red/orange dust;
- settling stage: 0.1--0.2 seconds, zero velocity plus downward force.

Direction is derived per target from the caster tile to the enemy tile. This makes the effect work for every facing direction rather than assuming left or right.

## Error handling

Particle construction should be a small helper function in the skill so each target uses the same data. It must guard against a missing brush and must not silently swallow unexpected exceptions; debug logging should identify the missing brush or error.

## Verification

- Static check: the script references `sand_dust_01` and calls the helper only for valid affected enemies.
- In-game: use Aura Routing with one, two, and three enemies in its arc. Each affected enemy should receive a visible red/orange dust burst and a lingering cloud; unaffected tiles should receive none.
- In-game: use the skill facing each hex direction to confirm the particle motion remains outward from the caster.
