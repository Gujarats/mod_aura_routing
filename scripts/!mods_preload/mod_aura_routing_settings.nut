::AuraRouting.registerSettings <- function()
{
	local page = ::AuraRouting.Mod.ModSettings.addPage("General");

	local sLevel = page.addRangeSetting("PerkLevel", ::AuraRouting.Tunables.LevelRequired, 5, 1, 7, 1, "Unlock Level Perk, Decide which Perk row this skills is available. Need Restart!!!");
    page.addRangeSetting(
        "PerkLevel",
        5, 1, 7, 1,
        "Perk Unlocked which rows in the menu perks",
        "NEED RESTART !!!"
    );

}
