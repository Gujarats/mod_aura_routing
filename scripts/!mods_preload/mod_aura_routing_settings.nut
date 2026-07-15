::AuraRouting.registerSettings <- function()
{
	try
	{
		local page = ::AuraRouting.MSU.ModSettings.addPage("Aura Routing");

		local sRadius = page.addRangeSetting("Radius", ::AuraRouting.Tunables.Radius, 1, 3, 1, "Routing Radius", "How many tiles the aura reaches.");
		sRadius.addAfterChangeCallback(function(_oldValue) {
			::AuraRouting.Tunables.Radius = this.getValue();
		});
		::AuraRouting.Tunables.Radius = sRadius.getValue();

		local sUses = page.addRangeSetting("UsesPerBattle", ::AuraRouting.Tunables.UsesPerBattle, 1, 3, 1, "Uses Per Battle", "How many times the routing aura can be used in one battle.");
		sUses.addAfterChangeCallback(function(_oldValue) {
			::AuraRouting.Tunables.UsesPerBattle = this.getValue();
		});
		::AuraRouting.Tunables.UsesPerBattle = sUses.getValue();

		local sLevel = page.addRangeSetting("LevelRequired", ::AuraRouting.Tunables.LevelRequired, 1, 10, 1, "Unlock Level", "Minimum level required to receive the routing perk.");
		sLevel.addAfterChangeCallback(function(_oldValue) {
			::AuraRouting.Tunables.LevelRequired = this.getValue();
		});
		::AuraRouting.Tunables.LevelRequired = sLevel.getValue();

		local sOnce = page.addBooleanSetting("IsOncePerBattle", ::AuraRouting.Tunables.IsOncePerBattle, "Once Per Battle", "If enabled, the user cannot take any further actions after using this skill.");
		sOnce.addAfterChangeCallback(function(_oldValue) {
			::AuraRouting.Tunables.IsOncePerBattle = this.getValue();
		});
		::AuraRouting.Tunables.IsOncePerBattle = sOnce.getValue();
	}
	catch (e)
	{
		::logError("Aura Routing: failed to build MSU settings - " + e);
	}
};
