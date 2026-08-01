if (!("DeveloperOptions" in ::AuraRouting))
{
	::AuraRouting.DeveloperOptions <- null;
}

::AuraRouting.DeveloperOptions = {
	function init()
	{
		::AuraRouting.DeveloperSession <- {
			HasGrantedResources = false
		};

		this.configureDebugLogging();
	}

	function isEnabled()
	{
		return ::AuraRouting.Mod.ModSettings.getSetting("EnableDeveloperOptions").getValue();
	}

	function configureDebugLogging()
	{
		if (this.isEnabled())
		{
			::AuraRouting.Mod.Debug.enable();
			::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] developer options enabled");
		}
		else
		{
			::AuraRouting.Mod.Debug.disable();
		}
	}

	function applyResourcesOnce()
	{
		if (!this.isEnabled())
		{
			return;
		}

		if (!::AuraRouting.Mod.ModSettings.getSetting("DeveloperGrantResourcesOnLoad").getValue())
		{
			return;
		}

		if (::AuraRouting.DeveloperSession.HasGrantedResources)
		{
			return;
		}

		if (!("World" in getroottable())
			|| ::World == null
			|| !("Assets" in ::World)
			|| ::World.Assets == null
			|| ::World.getPlayerRoster() == null)
		{
			return;
		}

		::AuraRouting.DeveloperSession.HasGrantedResources = true;

		::World.Assets.addMoney(50000);
		::World.Assets.addArmorParts(200);
		::World.Assets.addMedicine(200);
		::World.Assets.addAmmo(200);

		local roster = ::World.getPlayerRoster().getAll();
		foreach (bro in roster)
		{
			if (bro == null)
			{
				continue;
			}

			bro.addXP(10000, false);
			bro.updateLevel();
			bro.m.PerkPoints += 10;
		}

		::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] granted test resources and roster XP/perk points");
	}

	function grantAuraForTest( _entity )
	{
		if (!this.isEnabled())
		{
			return;
		}

		if (!::AuraRouting.Mod.ModSettings.getSetting("DeveloperGrantAuraOnLoad").getValue())
		{
			return;
		}

		if (_entity == null
			|| !("isPlayerControlled" in _entity)
			|| !_entity.isPlayerControlled()
			|| !("getSkills" in _entity))
		{
			return;
		}

		local skills = _entity.getSkills();
		if (skills == null)
		{
			return;
		}

		local background = _entity.getBackground();
		if (::Hooks.hasMod("mod_legends") && background != null)
		{
			local auraPerkDef = null;
			if ("Compatibility" in ::AuraRouting && "Legends" in ::AuraRouting.Compatibility)
			{
				auraPerkDef = ::AuraRouting.Compatibility.Legends.getAuraRoutingPerkDefNumber();
			}

			if (auraPerkDef != null && "addPerk" in background && "getPerk" in background)
			{
				if (background.getPerk("perk.aura_routing") == null)
				{
					background.addPerk(auraPerkDef, ::AuraRouting.Compatibility.Legends.getConfiguredRow(), true);
					::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] added Aura Routing to Legends background tree for " + _entity.getName());
				}
			}
			else
			{
				::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] Legends Aura perk definition not available; granting skill directly for " + _entity.getName());
			}
		}

		if (!skills.hasSkill("perk.aura_routing"))
		{
			skills.add(::new("scripts/skills/perks/aura_routing_perk"));
			skills.update();
			::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] granted Aura Routing perk skill to " + _entity.getName());
		}
	}
};
