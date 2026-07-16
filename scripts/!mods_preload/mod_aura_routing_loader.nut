::AuraRouting <- {
	ID = "mod_aura_routing",
	Name = "Aura Routing",
	Version = "1.0.0"
};

::AuraRouting.Tunables <- {
	Radius = 3,
	UsesPerBattle = 1,
	LevelRequired = 7,
	IsOncePerBattle = true
};

::AuraRouting.HookMod <- ::Hooks.register(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
::AuraRouting.HookMod.require("mod_msu >= 1.9.0");

::AuraRouting.HookMod.queue(">mod_msu", function()
{
	::AuraRouting.Mod <- ::MSU.Class.Mod(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
	::AuraRouting.registerSettings();
	::AuraRouting.Mod.Debug.enable()
	::AuraRouting.Mod.Debug.printLog("[AuraRouting] settings initialized for Aura Routing mod completed");

	local mod = ::AuraRouting.HookMod;

 	::Hooks.registerJS("ui/mods/aura_routing.js");
	::Hooks.registerCSS("ui/mods/aura_routing.css");
	mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function(_entity, _activeEntity)
		{
			local result = __original(_entity, _activeEntity);
			if (_entity != null)
			{
				local skills = _entity.getSkills();
				local settings = ::AuraRouting.Mod.ModSettings;
				local sLevel = settings.getSetting("PerkLevel").getValue();
				if (skills != null)
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
							p.druid_blocked <- false;
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
});
