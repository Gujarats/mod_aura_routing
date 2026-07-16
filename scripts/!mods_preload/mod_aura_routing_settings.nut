::AuraRouting.registerSettings <- function()
{
	local page = ::AuraRouting.Mod.ModSettings.addPage("General");

    page.addRangeSetting(
        "PerkLevel",
        5, 1, 7, 1,
        "Perk Unlocked which rows in the menu perks",
        "NEED RESTART !!!"
    );

}
