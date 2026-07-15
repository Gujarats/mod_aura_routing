# Works still in progress this mod does not work
 - wait for me to upload and test first
 
# Aura Supreme Mod

An active ability and perk modification for **Battle Brothers**, built using the Modding Standards & Utilities (MSU) framework and Modern Hooks. 

This mod introduces a terrifying, high-tier ability that allows an elite character to completely shatter the morale of surrounding enemies, forcing them into an immediate rout once per battle.

## 🚀 Features

* **Custom Active Skill ("Aura Supreme"):** Forces all enemies within a specified tile radius to instantly fail their morale checks and transition into the **Fleeing** state.
* **Dynamic Menu Configuration (MSU):** No script editing required. Adjust balance variables directly from the in-game Mod Settings menu.
* **Perk Tree Integration:** Fully integrated into the character perk tree grid as a pickable talent.

## ⚙️ Dynamic Configurations (In-Game Settings)

Through the **Mod Settings** menu, you can dynamically configure the following parameters on the fly:

1. **Perk Level Requirement:** Adjust which level row (Tier 1 to 10) the perk appears on (Default: Row 7).
2. **Once Per Battle Restriction:** Toggle whether the ability can only be cast a single time per combat encounter, or used continuously (Default: Enabled).
3. **Aura Effect Radius:** Dynamically scale the area of effect from 1 to 3 tiles out from the caster (Default: 3 Tiles).

## 📁 Repository & Folder Structure

The project code maintains a strict separation of concerns, separating early game engine initialization from runtime combat logic loops:
source image : https://media.craiyon.com/2025-07-15/MkCFt4X6Ql2ltI2iZdSUew.webp 

```text
├── gfx/
│   ├── skills/
│   │   ├── aura_supreme_icon.png        # 64x64 Active Skill Icon
│   │   └── aura_supreme_icon_sw.png     # 64x64 Grayscale (Disabled) Icon
│   └── ui/
│       └── perks/
│           ├── aura_supreme_perk.png    # 44x44 Perk Tree Icon
│           └── aura_supreme_perk_sw.png # 44x44 Grayscale (Disabled) Perk Icon
├── scripts/
│   └── !mods_preload/
│       └── mod_aura_supreme_loader.nut  # Handles MSU initialization & UI layouts
├── mod_aura_supreme_logic.nut           # Hooks into tactical actors & injection logic
└── mod_aura_supreme_skill.nut           # Core active skill behavior & mechanics
```

# 🛠️ Requirements
To run this mod, ensure you have the following frameworks installed in your game data directory:

Modern Hooks

Modding Standards & Utilities (MSU) >= 1.9.0

# 💻 Installation
Download the latest release .zip file.

Drop the zip file directly into your Battle Brothers data/ directory:
.../Steam/steamapps/common/Battle Brothers/data/

Launch the game and look for Aura Supreme Mod inside your Mod Settings panel!

# 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.
