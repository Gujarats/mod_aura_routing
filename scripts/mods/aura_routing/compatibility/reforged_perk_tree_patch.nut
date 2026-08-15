if (!("AuraRouting" in getroottable()))
{
	::AuraRouting <- {};
}

if (!("Compatibility" in ::AuraRouting))
{
	::AuraRouting.Compatibility <- {};
}

::AuraRouting.Compatibility.Reforged <- {
	ExistingPlayersMigrated = false,

	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_reforged")
			&& ("DynamicPerks" in getroottable())
			&& ("Perks" in ::DynamicPerks)
			&& ("PerkGroups" in ::DynamicPerks)
			&& ("addPerks" in ::DynamicPerks.Perks)
			&& ("findById" in ::DynamicPerks.PerkGroups);
	},

	function getConfiguredRow()
	{
		local row = ::AuraRouting.Mod.ModSettings.getSetting("PerkLevel").getValue();
		return ::Math.max(1, ::Math.min(row, 7));
	},

	function registerPerkDefinition()
	{
		if (::Const.Perks.findById("perk.aura_routing") != null)
		{
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing perk definition already registered");
			return true;
		}

		local perk = ::AuraRouting.getAuraRoutingPerkDefinition();
		delete perk.Row;
		::DynamicPerks.Perks.addPerks([perk]);
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing perk definition registered");
		return true;
	},

	function addAuraRoutingToUniversalGroup()
	{
		local group = ::DynamicPerks.PerkGroups.findById("pg.rf_always_1");
		if (group == null)
		{
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing insertion skipped: universal perk group is unavailable");
			return false;
		}

		local tree = group.getTree();
		foreach (i, perks in tree)
		{
			foreach (perkID in perks)
			{
				if (perkID == "perk.aura_routing")
				{
					::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing already present in universal perk group row=" + (i + 1));
					return true;
				}
			}
		}

		local row = this.getConfiguredRow();
		while (tree.len() < row)
		{
			tree.push([]);
		}

		tree[row - 1].push("perk.aura_routing");
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing inserted into universal perk group row=" + row);
		return true;
	},

	function addAuraRoutingToExistingPlayerTrees()
	{
		if (!this.hasRuntime()
			|| !("World" in getroottable())
			|| ::World.getPlayerRoster() == null)
		{
			return false;
		}

		local added = 0;
		local alreadyPresent = 0;
		local unavailable = 0;
		foreach (actor in ::World.getPlayerRoster().getAll())
		{
			if (actor == null)
			{
				unavailable++;
				continue;
			}

			local perkTree = actor.getPerkTree();
			if (perkTree == null)
			{
				unavailable++;
				continue;
			}

			if ("perk.aura_routing" in perkTree.getPerks())
			{
				alreadyPresent++;
				continue;
			}

			perkTree.addPerk("perk.aura_routing", this.getConfiguredRow());
			added++;
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing added to existing player perk tree for " + actor.getName() + " row=" + this.getConfiguredRow());
		}

		::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] existing-player Aura Routing migration complete added=" + added + " already_present=" + alreadyPresent + " unavailable=" + unavailable);
		return true;
	},

	function tryMigrateExistingPlayerTrees()
	{
		if (this.ExistingPlayersMigrated) return true;
		if (!this.hasRuntime()
			|| !("World" in getroottable())
			|| ::World.getPlayerRoster() == null
			|| ::World.getPlayerRoster().getAll().len() == 0)
		{
			return false;
		}

		this.addAuraRoutingToExistingPlayerTrees();
		this.ExistingPlayersMigrated = true;
		return true;
	},

	function register()
	{
		if (!this.hasRuntime())
		{
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Aura Routing registration skipped: required Dynamic Perks APIs are unavailable");
			return false;
		}

		if (!this.registerPerkDefinition()) return false;
		return this.addAuraRoutingToUniversalGroup();
	}
};
