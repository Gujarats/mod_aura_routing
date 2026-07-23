::AuraRouting.registerSettings <- function()
{
	local page = ::AuraRouting.Mod.ModSettings.addPage("General");

	page.addRangeSetting("UsesPerBattle",
		1, 1, 3, 1,
		"Uses Per Battle",
		"How many times the character uses the skill aura can be used in one battle."
	);

	page.addRangeSetting("MoraleResolvePenalty", 10, 0, 50, 1, "Morale Resolve Penalty", "Penalty applied to enemy Resolve checks made against Aura Routing.");
	page.addRangeSetting("MoraleDropSteps", 1, 1, 3, 1, "Morale Drop Steps", "How many morale steps an enemy loses after failing the Aura Routing resolve check.");
	page.addBooleanSetting("AllowFleeingOnAlreadyWavering", true, "Fleeing From Wavering", "When enabled, enemies already Wavering can become Fleeing after failing the Aura Routing resolve check.");

	page.addRangeSetting("AttackHitChanceBonus", 0, -30, 30, 1, "Attack Hit Chance Bonus", "Flat hit chance modifier for Aura Routing attacks.");
	page.addRangeSetting("AttackDamageMin", 15, 0, 100, 1, "Attack Minimum Damage", "Minimum regular damage for a landed Aura Routing attack.");
	page.addRangeSetting("AttackDamageMax", 30, 0, 150, 1, "Attack Maximum Damage", "Maximum regular damage for a landed Aura Routing attack.");
	page.addRangeSetting("AttackArmorDamageMultPct", 75, 0, 200, 5, "Attack Armor Damage (%)", "Armor damage multiplier for a landed Aura Routing attack.");
	page.addRangeSetting("AttackDirectDamagePct", 10, 0, 100, 1, "Attack Direct Damage (%)", "Share of regular damage that can pass through armor on a landed Aura Routing attack.");

	page.addRangeSetting("NoAffectedMeleeDefense", 35, 0, 100, 1, "No Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects no enemies.");
	page.addRangeSetting("NoAffectedRangedDefense", 25, 0, 100, 1, "No Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects no enemies.");
	page.addRangeSetting("OneAffectedMeleeDefense", 20, 0, 100, 1, "One Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects one enemy.");
	page.addRangeSetting("OneAffectedRangedDefense", 15, 0, 100, 1, "One Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects one enemy.");
	page.addRangeSetting("TwoAffectedMeleeDefense", 10, 0, 100, 1, "Two Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects two enemies.");
	page.addRangeSetting("TwoAffectedRangedDefense", 5, 0, 100, 1, "Two Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects two enemies.");

    page.addRangeSetting(
        "PerkLevel",
        5, 1, 7, 1,
        "Perk Unlocked which rows in the menu perks",
        "NEED RESTART !!!"
    );

}
