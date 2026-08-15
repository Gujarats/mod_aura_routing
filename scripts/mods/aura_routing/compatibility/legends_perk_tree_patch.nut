if (!("Compatibility" in ::AuraRouting))
{
	::AuraRouting.Compatibility <- {};
}

if (!("Legends" in ::AuraRouting.Compatibility))
{
	::AuraRouting.Compatibility.Legends <- null;
}

::AuraRouting.Compatibility.Legends = {
	AuraRoutingPerkDef = null,

	function getConfiguredRow()
	{
		local row = ::AuraRouting.Mod.ModSettings.getSetting("PerkLevel").getValue() - 1;
		return row < 0 ? 0 : row;
	}

	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_legends")
			&& ("Legends" in getroottable())
			&& ("Perk" in ::Legends)
			&& ("PerkDefObjects" in ::Const.Perks)
			&& ("addPerkDefObjects" in ::Const.Perks);
	}

	function setAuraRoutingPerkDef( _perkDef )
	{
		if (!("AuraRouting" in ::Legends.Perk))
		{
			::Legends.Perk.AuraRouting <- _perkDef;
		}
		else
		{
			::Legends.Perk.AuraRouting = _perkDef;
		}

		if (!("AuraRouting" in ::Const.Perks.PerkDefs))
		{
			::Const.Perks.PerkDefs.AuraRouting <- _perkDef;
		}
		else
		{
			::Const.Perks.PerkDefs.AuraRouting = _perkDef;
		}
	}

	function registerPerkDef()
	{
		if (!this.hasRuntime())
		{
			this.AuraRoutingPerkDef = null;
			return null;
		}

		if (!("AuraRouting" in ::Const.Strings.PerkName))
		{
			::Const.Strings.PerkName.AuraRouting <- "Aura Routing";
		}

		if (!("AuraRouting" in ::Const.Strings.PerkDescription))
		{
			::Const.Strings.PerkDescription.AuraRouting <- "Unlocks the Aura Routing active skill.";
		}

		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.aura_routing")
			{
				this.setAuraRoutingPerkDef(i);
				this.AuraRoutingPerkDef = i;
				return i;
			}
		}

		this.setAuraRoutingPerkDef(null);
		local perk = ::AuraRouting.getAuraRoutingPerkDefinition();
		delete perk.Row;
		::Const.Perks.addPerkDefObjects([perk]);

		this.AuraRoutingPerkDef = ::Legends.Perk.AuraRouting;
		return this.AuraRoutingPerkDef;
	}

	function getAuraRoutingPerkDefNumber()
	{
		if (this.AuraRoutingPerkDef != null)
		{
			return this.AuraRoutingPerkDef;
		}

		if (!::Hooks.hasMod("mod_legends")
			|| !("PerkDefObjects" in ::Const.Perks)
			|| ::Const.Perks.PerkDefObjects == null)
		{
			return null;
		}

		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.aura_routing")
			{
				this.AuraRoutingPerkDef = i;
				return i;
			}
		}

		return null;
	}

	function addAuraToBackground( _background )
	{
		if (!::Hooks.hasMod("mod_legends") || _background == null)
		{
			return false;
		}

		local auraRoutingLegendsPerkDef = this.getAuraRoutingPerkDefNumber();
		if (auraRoutingLegendsPerkDef == null
			|| _background.m.PerkTreeMap == null
			|| _background.getPerk("perk.aura_routing") != null)
		{
			return false;
		}

		return _background.addPerk(auraRoutingLegendsPerkDef, this.getConfiguredRow(), true);
	}

	function registerHooks( _mod )
	{
		this.registerPerkDef();

		if (!::Hooks.hasMod("mod_legends"))
		{
			return;
		}

		local module = ::AuraRouting.Compatibility.Legends;
		_mod.hook("scripts/skills/backgrounds/character_background", function(q)
		{
			q.buildPerkTree = @(__original) function()
			{
				local attributes = __original();
				module.addAuraToBackground(this);
				return attributes;
			}
		});
	}
};
