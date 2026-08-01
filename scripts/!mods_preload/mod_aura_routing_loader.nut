::AuraRouting <- {
	ID = "mod_aura_routing",
	Name = "Aura Routing",
	Version = "0.0.8"
};

::AuraRouting.HookMod <- ::Hooks.register(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
::AuraRouting.HookMod.require("mod_msu >= 1.9.0");

::AuraRouting.HookMod.queue(">mod_msu", ">mod_legends", ">mod_necro", function()
{
	::AuraRouting.Mod <- ::MSU.Class.Mod(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
	::AuraRouting.registerSettings();

	local mod = ::AuraRouting.HookMod;

	::AuraRouting.DeveloperSession <- {
		HasGrantedResources = false
	};

	local function isAuraRoutingDeveloperOptionsEnabled()
	{
		return ::AuraRouting.Mod.ModSettings.getSetting("EnableDeveloperOptions").getValue();
	}

	if (isAuraRoutingDeveloperOptionsEnabled())
	{
		::AuraRouting.Mod.Debug.enable();
		::AuraRouting.Mod.Debug.printLog("[AuraRouting][Developer] developer options enabled");
	}
	else
	{
		::AuraRouting.Mod.Debug.disable();
	}

	::AuraRouting.Mod.Debug.printLog("[AuraRouting] settings initialized for Aura Routing mod completed");

	local function getAuraRoutingConfiguredRow()
	{
		local row = ::AuraRouting.Mod.ModSettings.getSetting("PerkLevel").getValue() - 1;
		return row < 0 ? 0 : row;
	}

	local function setAuraRoutingLegendsPerkDef( _perkDef )
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

	local function registerAuraRoutingPerkDefForLegends()
	{
		if (!::Hooks.hasMod("mod_legends")
			|| !("Legends" in getroottable())
			|| !("Perk" in ::Legends)
			|| !("PerkDefObjects" in ::Const.Perks)
			|| !("addPerkDefObjects" in ::Const.Perks))
		{
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
				setAuraRoutingLegendsPerkDef(i);
				return i;
			}
		}

		setAuraRoutingLegendsPerkDef(null);
		::Const.Perks.addPerkDefObjects([
			{
				ID = "perk.aura_routing",
				Script = "scripts/skills/perks/aura_routing_perk",
				Name = "Aura Routing",
				Tooltip = "Unlocks the Aura Routing active skill.",
				Icon = "aura/aura_routing_perk.png",
				IconDisabled = "aura/aura_routing_perk_sw.png",
				Const = "AuraRouting"
			}
		]);

		return ::Legends.Perk.AuraRouting;
	}

	local auraRoutingLegendsPerkDef = registerAuraRoutingPerkDefForLegends();

	local function applyAuraRoutingDeveloperResourcesOnce()
	{
		if (!isAuraRoutingDeveloperOptionsEnabled())
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

	local function findAuraRoutingLegendsPerkDefNumber()
	{
		if (auraRoutingLegendsPerkDef != null)
		{
			return auraRoutingLegendsPerkDef;
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
				auraRoutingLegendsPerkDef = i;
				return i;
			}
		}

		return null;
	}

	local function grantAuraRoutingForDeveloperTest( _entity )
	{
		if (!isAuraRoutingDeveloperOptionsEnabled())
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
			local auraPerkDef = findAuraRoutingLegendsPerkDefNumber();
			if (auraPerkDef != null && "addPerk" in background && "getPerk" in background)
			{
				if (background.getPerk("perk.aura_routing") == null)
				{
					background.addPerk(auraPerkDef, getAuraRoutingConfiguredRow(), true);
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

	mod.hook("scripts/skills/backgrounds/character_background", function(q)
	{
		q.buildPerkTree = @(__original) function()
		{
			local attributes = __original();

			if (::Hooks.hasMod("mod_legends")
				&& auraRoutingLegendsPerkDef != null
				&& this.m.PerkTreeMap != null
				&& this.getPerk("perk.aura_routing") == null)
			{
				this.addPerk(auraRoutingLegendsPerkDef, getAuraRoutingConfiguredRow(), true);
			}

			return attributes;
		}
	});

	::Hooks.registerJS("ui/mods/aura_routing.js");
	::Hooks.registerCSS("ui/mods/aura_routing.css");
	mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function(_entity, _activeEntity)
		{
			local result = __original(_entity, _activeEntity);
			applyAuraRoutingDeveloperResourcesOnce();
			grantAuraRoutingForDeveloperTest(_entity);

			if (_entity != null)
			{
				local skills = _entity.getSkills();
				local isNecro = skills != null && skills.hasSkill("background.necro");
				local settings = ::AuraRouting.Mod.ModSettings;
				local sLevel = settings.getSetting("PerkLevel").getValue();
				if (skills != null && !isNecro)
				{
					// NOTES hardcoded to check the mod "proper druid"
					// TODO need to change to proper id
					local showTree = _entity!=null && !_entity.getSkills().hasSkill("background.hackflows_druid");
					if (showTree)
					{
						if (::Hooks.hasMod("mod_legends"))
						{
							return result;
						}

						local perks = ::Const.Perks.Perks.map(@(row) clone row);
						// data coming from config/z_aura.nut
						foreach (perk in ::Const.Perks.Aura) {
							local p = clone perk;
							delete p.verifyPrerequisites;
							perks[sLevel-1].push(p);
						}
						result.aura_routing_perkTree <- perks;
						::AuraRouting.Mod.Debug.printLog("[AuraRouting] convertEntityToUIData injecting aura_routing_perkTree for " + _entity.getName());
					}
				}
			}
			return result;
		}
	});

	mod.hook("scripts/entity/tactical/actor", function(q)
	{
		q.getTooltip = @(__original) function( _targetedWithSkill = null )
		{
			local tooltip = __original(_targetedWithSkill);

			if (_targetedWithSkill != null
				&& _targetedWithSkill.getID() == "actives.aura_routing"
				&& "getAuraRoutingTargetTooltip" in _targetedWithSkill)
			{
				local auraRoutingLines = _targetedWithSkill.getAuraRoutingTargetTooltip(this);
				foreach (line in auraRoutingLines)
				{
					tooltip.push(line);
				}
			}

			return tooltip;
		}
	});
});
