if (!("AuraRouting" in getroottable()))
{
	::AuraRouting <- {};
}

::AuraRouting.ID <- "mod_aura_routing";
::AuraRouting.Name <- "Aura Routing";
::AuraRouting.Version <- "0.2.1";

::AuraRouting.HookMod <- ::Hooks.register(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
::AuraRouting.HookMod.require("mod_msu >= 1.9.0");

::AuraRouting.configureDebugLogging <- function()
{
	if ("GuzBluezDebugLogController" in getroottable()
		&& "registerTarget" in ::GuzBluezDebugLogController)
	{
		::GuzBluezDebugLogController.registerTarget(::AuraRouting.ID, ::AuraRouting.Mod);
		return;
	}

	::AuraRouting.Mod.Debug.setFlag("default", ::AuraRouting.Mod.ModSettings.getSetting("DebugLogging").getValue());
};

::include("scripts/mods/aura_routing/compatibility/legends_perk_tree_patch");
::include("scripts/mods/aura_routing/compatibility/reforged_perk_tree_patch");

::AuraRouting.HookMod.queue(">mod_msu", ">mod_legends", ">mod_necro", ">mod_reforged", function()
{
	::AuraRouting.Mod <- ::MSU.Class.Mod(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
	::AuraRouting.registerSettings();
	::AuraRouting.configureDebugLogging();

	local mod = ::AuraRouting.HookMod;

	::AuraRouting.Mod.Debug.printLog("[AuraRouting] settings initialized for Aura Routing mod completed");
	if (::Hooks.hasMod("mod_reforged"))
	{
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] Dynamic Perks compatibility selected");
	}
	else
	{
		::AuraRouting.Compatibility.Legends.registerHooks(mod);
	}

	::Hooks.registerJS("ui/mods/aura_routing.js");
	::Hooks.registerCSS("ui/mods/aura_routing.css");
	mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function(_entity, _activeEntity)
		{
			local result = __original(_entity, _activeEntity);
			if (::Hooks.hasMod("mod_legends") || ::Hooks.hasMod("mod_reforged"))
			{
				if (_entity != null && ::Hooks.hasMod("mod_reforged"))
				{
					::AuraRouting.Mod.Debug.printLog("[AuraRouting] [Reforged] skipped UI-only Aura Routing injection for " + _entity.getName());
				}

				return result;
			}

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

	// for mod Reforged,works for existing saves
	mod.hook("scripts/states/world_state", function(q)
	{
		q.onUpdate = @(__original) function()
		{
			__original();
			::AuraRouting.Compatibility.Reforged.tryMigrateExistingPlayerTrees();
		}
	});
});

::AuraRouting.HookMod.queue(">mod_reforged", function()
{
	::AuraRouting.Compatibility.Reforged.register();
}, ::Hooks.QueueBucket.AfterHooks);
