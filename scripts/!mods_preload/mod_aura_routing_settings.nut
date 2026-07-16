::AuraRouting.registerSettings <- function()
{
	local page = ::AuraRouting.Mod.ModSettings.addPage("General");

	page.addRangeSetting("UsesPerBattle",
		1, 1, 3, 1,
		"Uses Per Battle",
		"How many times the character uses the skill aura can be used in one battle."
	);

    page.addRangeSetting(
        "PerkLevel",
        5, 1, 7, 1,
        "Perk Unlocked which rows in the menu perks",
        "NEED RESTART !!!"
    );

}
