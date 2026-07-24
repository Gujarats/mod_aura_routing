# Aura Routing - Make them Run !!!

An active ability and perk modification for **Battle Brothers**, built using the Modding Standards & Utilities (MSU) framework and Modern Hooks. 

This mod introduces a terrifying, high-tier ability that lets an elite character attack nearby enemies with aura pressure, damage them on landed hits, and shake their morale without guaranteeing a rout.

## Special thanks to
 - [Proper Druid](https://www.nexusmods.com/battlebrothers/mods/1061)
 - [Legends](https://www.nexusmods.com/battlebrothers/mods/60)
 - [Aura Power](https://www.nexusmods.com/battlebrothers/mods/1035)

## icon
source  image : https://media.craiyon.com/2025-07-15/MkCFt4X6Ql2ltI2iZdSUew.webp 

## 🚀 Features

* **Custom Active Skill ("Aura Routing"):** Aura Routing attacks up to three enemies in a frontal arc using normal hit chance. Landed hits can damage armor and hitpoints, then force a Resolve check; enemies that fail lose morale, and enemies already near breaking can be forced into flight depending on settings. If the aura fails to affect many enemies, unused force returns to the caster as temporary Melee and Ranged Defense until their next turn. When Aura Routing is selected, hovering a highlighted enemy shows its morale drop chance on hit.
* **Dynamic Menu Configuration (MSU):** No script editing required. Adjust balance variables directly from the in-game Mod Settings menu.
* **Perk Tree Integration:** Fully integrated into the character perk tree grid as a pickable talent.

## ⚙️ Dynamic Configurations (In-Game Settings)

Through the **Mod Settings** menu, you can dynamically configure the following parameters on the fly:

1. **Uses Per Battle:** Adjust how many times each character can use Aura Routing per battle.
2. **Perk Level:** Adjust which perk row unlocks Aura Routing.
3. **Morale Resolve Penalty:** Adjust how hard the follow-up Resolve check is after a landed hit.
4. **Morale Drop Steps:** Adjust how many morale levels a failed Resolve check removes.
5. **Fleeing From Wavering:** Allow Wavering enemies to collapse directly into Fleeing after a failed check.
6. **Attack Hit Chance Bonus:** Adjust the flat hit chance modifier for Aura Routing attacks.
7. **Attack Minimum/Maximum Damage:** Adjust regular damage dealt by landed Aura Routing attacks.
8. **Attack Armor Damage:** Adjust armor damage dealt by landed Aura Routing attacks.
9. **Attack Direct Damage:** Adjust how much landed attack damage can pass through armor.
10. **No Effect Melee/Ranged Defense:** Defense gained until next turn if no enemies are affected.
11. **One Effect Melee/Ranged Defense:** Defense gained until next turn if one enemy is affected.
12. **Two Effect Melee/Ranged Defense:** Defense gained until next turn if two enemies are affected.


# 🛠️ Requirements
To run this mod, ensure you have the following frameworks installed in your game data directory:

 - Modern Hooks

 - Modding Standards & Utilities (MSU) >= 1.9.0

# 💻 Installation
Download the latest release .zip file.

Drop the zip file directly into your Battle Brothers data/ directory:
.../Steam/steamapps/common/Battle Brothers/data/

Launch the game and look for Aura Supreme Mod inside your Mod Settings panel!

# 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.

# Known Issue
 - start the hit animation somehow cannot be trigger without attack/damaged, need to find a way to tigger damange animation with 0 damage
 - overlay icon somehow does not look as good as the vanilla
