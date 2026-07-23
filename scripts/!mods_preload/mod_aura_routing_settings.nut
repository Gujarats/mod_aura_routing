::AuraRouting.registerSettings <- function()
{
	local general = ::AuraRouting.Mod.ModSettings.addPage("General");
	local attack = ::AuraRouting.Mod.ModSettings.addPage("Attack");
	local morale = ::AuraRouting.Mod.ModSettings.addPage("Morale");
	local fallback = ::AuraRouting.Mod.ModSettings.addPage("Fallback Defense");

	general.addRangeSetting("UsesPerBattle",
		1, 1, 3, 1,
		"Uses Per Battle",
		"How many times each character can use Aura Routing in one battle."
	);

	general.addRangeSetting(
		"PerkLevel",
		5, 1, 7, 1,
		"Perk Row",
		"Which perk row unlocks Aura Routing. Requires restart."
	);

	attack.addRangeSetting("AttackHitChanceBonus", 0, -30, 30, 1, "Attack Hit Chance Bonus", "Flat hit chance modifier for Aura Routing attacks.");
	attack.addRangeSetting("AttackDamageMin", 15, 0, 100, 1, "Attack Minimum Damage", "Minimum regular damage for a landed Aura Routing attack.");
	attack.addRangeSetting("AttackDamageMax", 30, 0, 150, 1, "Attack Maximum Damage", "Maximum regular damage for a landed Aura Routing attack.");
	attack.addRangeSetting("AttackArmorDamageMultPct", 75, 0, 200, 5, "Attack Armor Damage (%)", "Armor damage multiplier for a landed Aura Routing attack.");
	attack.addRangeSetting("AttackDirectDamagePct", 10, 0, 100, 1, "Attack Direct Damage (%)", "Share of regular damage that can pass through armor on a landed Aura Routing attack.");

	morale.addRangeSetting("MoraleResolvePenalty", 10, 0, 50, 1, "Morale Resolve Penalty", "Penalty applied to enemy Resolve checks made against Aura Routing.");
	morale.addRangeSetting("MoraleDropSteps", 1, 1, 3, 1, "Morale Drop Steps", "How many morale steps an enemy loses after failing the Aura Routing resolve check.");
	morale.addBooleanSetting("AllowFleeingOnAlreadyWavering", true, "Fleeing From Wavering", "When enabled, enemies already Wavering can become Fleeing after failing the Aura Routing resolve check.");

	fallback.addRangeSetting("NoAffectedMeleeDefense", 35, 0, 100, 1, "No Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects no enemies.");
	fallback.addRangeSetting("NoAffectedRangedDefense", 25, 0, 100, 1, "No Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects no enemies.");
	fallback.addRangeSetting("OneAffectedMeleeDefense", 20, 0, 100, 1, "One Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects one enemy.");
	fallback.addRangeSetting("OneAffectedRangedDefense", 15, 0, 100, 1, "One Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects one enemy.");
	fallback.addRangeSetting("TwoAffectedMeleeDefense", 10, 0, 100, 1, "Two Effect Melee Defense", "Melee Defense gained until next turn if Aura Routing affects two enemies.");
	fallback.addRangeSetting("TwoAffectedRangedDefense", 5, 0, 100, 1, "Two Effect Ranged Defense", "Ranged Defense gained until next turn if Aura Routing affects two enemies.");
}
