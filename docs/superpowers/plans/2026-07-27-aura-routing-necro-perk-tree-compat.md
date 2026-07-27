# Aura Routing + Necro perk tree compatibility plan

## Goal

Keep Necromancer perk tree behavior from `mod_necro` intact when both `mod_aura_routing` and `mod_necro` are loaded together.

## Constraints

- Do not modify `mod_necro`.
- Do not modify `mod_bandages_enhanced` in this fix.
- Keep existing Aura Routing behavior unchanged for non-Necro characters.

## Problem

`mod_aura_routing` injects `aura_routing_perkTree` and its UI hook can override `necro_perkTree` depending on hook chain order.

## Planned changes

1. In `mod_aura_routing/scripts/!mods_preload/mod_aura_routing_loader.nut`:
   - Add queue dependency on `mod_necro` so Aura Routing registration runs after `mod_necro`.
   - Skip Aura Routing perk tree injection for Necro entities (`background.necro`) to prevent conflicting tree data.
2. In `mod_aura_routing/ui/mods/aura_routing.js`:
   - Only route to `aura_routing_perkTree` when `necro_perkTree` is not present.

## Expected result

- Necro characters keep `necro_perkTree` as their active tree.
- Non-necro characters keep Aura Routing perk tree behavior.
- No changes to `mod_necro` are required.
