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
    Icon = "aura/aura_pulse.png"
    IconDisabled = "aura/aura_pulse_sw.png"
    Row = 1
})
