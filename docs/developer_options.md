# Developer Options

Developer options are opt-in test helpers for faster in-game validation of Aura Routing. They are disabled by default and are not intended for normal campaigns.

## Settings

- `EnableDeveloperOptions`: master switch. When disabled, no developer action runs.
- `DebugLogging`: when enabled, Aura Routing writes debug lines to `log.html`. This can be changed from Mod Settings during a session.
- `DeveloperGrantAuraOnLoad`: when enabled, roster characters receive the Aura Routing perk skill when their UI data is converted.
- `DeveloperGrantResourcesOnLoad`: when enabled, the current roster receives test XP and perk points, and the company receives crowns and supplies once per game session.

## Runtime Behavior

The first version does not add a hotkey. It applies through existing roster UI data conversion so it avoids keybind conflicts with Legends, Breditor, BBForge, and other UI-heavy mods.

In Legends games, if Aura Routing has already been registered as a real Legends perk definition, the developer helper also tries to add Aura to the character background tree through `background.addPerk(...)`. If that registration is not available yet, the helper grants the Aura Routing perk skill directly so combat testing remains possible.

## Safety Notes

These helpers mutate the active campaign state. Use them on disposable test saves. Keep the developer options disabled in normal campaigns.
