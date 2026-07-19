// This config file is loaded before the game starts, and is used to add new perks to the game.
// it uses vanilla game code to load the file config
// this will be loaded after all vanilla config and assets loaded
// then after that, the script in !mods-preload will be loaded, which will load the perk into the game
//  AI explaination
//   So the typical order is:
//   1. Game begins preload
//   2. Vanilla scripts/config/perks.nut creates the normal perk registry
//   3. Mod scripts/config/z_aura.nut runs automatically
//      → creates ::Const.Perks.Aura
//      → registers perk.aura_routing in LookupMap
//   4. Modern Hooks runs scripts/!mods_preload/mod_aura_routing_loader.nut
//   5. Its convertEntityToUIData hook later reads ::Const.Perks.Aura
//   That is why you do not see an explicit include("scripts/config/z_aura") in the loader: it has already been executed
//   during the engine’s automatic scripts/config scan.

::Const.Perks.Aura <- [];

local function addPerk(perk) {
    perk.Unlocks <- perk.Row;
    perk.verifyPrerequisites <- function (_player, _tooltip) {
        // local reason = ::Const.Druid.perkBlockReason(this.ID, _player.getSkills());
        // if (reason == null) return true;
        // _tooltip.push({id = 3, type = "hint", icon = "ui/icons/icon_locked.png", text = reason});
        return true;
    }
    ::Const.Perks.Aura.push(perk);
    ::Const.Perks.LookupMap[perk.ID] <- perk;
}

addPerk({
    ID = "perk.aura_routing"
    Script = "scripts/skills/perks/aura_routing_perk"
    Name = "Aura Routing"
    Tooltip = "Unlocks the Aura Routing active skill."
    Icon = "aura/aura_routing_perk.png"
    IconDisabled = "aura/aura_routing_perk_sw.png"
    // replaced with MSU setting option
    Row = 4
})
