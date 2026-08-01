::AuraRouting <- {
	ID = "mod_aura_routing",
	Name = "Aura Routing",
	Version = "0.1.0"
};

::AuraRouting.HookMod <- ::Hooks.register(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
::AuraRouting.HookMod.require("mod_msu >= 1.9.0");

::include("scripts/mods/aura_routing/developer_options");
::include("scripts/mods/aura_routing/compatibility/legends_perk_tree_patch");

::AuraRouting.HookMod.queue(">mod_msu", ">mod_legends", ">mod_necro", function()
{
	::AuraRouting.Mod <- ::MSU.Class.Mod(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
	::AuraRouting.registerSettings();

	local mod = ::AuraRouting.HookMod;

	::AuraRouting.DeveloperOptions.init();
	::AuraRouting.Mod.Debug.printLog("[AuraRouting] settings initialized for Aura Routing mod completed");
	::AuraRouting.Compatibility.Legends.registerHooks(mod);

	::Hooks.registerJS("ui/mods/aura_routing.js");
	::Hooks.registerCSS("ui/mods/aura_routing.css");
	mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function(_entity, _activeEntity)
		{
			local result = __original(_entity, _activeEntity);
			::AuraRouting.DeveloperOptions.applyResourcesOnce();
			::AuraRouting.DeveloperOptions.grantAuraForTest(_entity);

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
