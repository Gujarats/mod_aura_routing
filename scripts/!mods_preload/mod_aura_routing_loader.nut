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
	mod.hook("scripts/entity/tactical/actor", function(q)
	{
		q.addXP = @(__original) function(_xp, _scale = true)
		{
			local ret = __original(_xp, _scale);
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] actor.addXP hook fired for " + this.getName() + " with xp=" + _xp);
			::AuraRouting.grantPerkIfEligible(this);
			return ret;
		}
	});

	mod.hook("scripts/entity/tactical/player", function(q)
	{
		q.onHired = @(__original) function()
		{
			local ret = __original();
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] player.onHired hook fired for " + this.getName());
			::AuraRouting.grantPerkIfEligible(this);
			return ret;
		}
	});

	mod.hook("scripts/skills/skill_container", function(q)
	{
		q.update = @(__original) function()
		{
			local ret = __original();
			local actor = this.getActor();
			if (actor != null)
			{
				::AuraRouting.Mod.Debug.printLog("[AuraRouting] skill_container.update hook fired for " + actor.getName());
				::AuraRouting.grantPerkIfEligible(actor);
			}

			return ret;
		}
	});

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
				if (skills != null)
				{
					local showTree = _entity!=null && !_entity.getSkills().hasSkill("background.hackflows_druid");
					if (showTree)
					{
						::AuraRouting.Mod.Debug.printLog("[AuraRouting] convertEntityToUIData injecting aura_routing_perkTree for " + _entity.getName());
						local perks = ::Const.Perks.Perks.map(@(row) clone row);
						local p = ::new("scripts/skills/perks/aura_routing_perk");
						p.aura_routing_locked <- _entity.getLevel() < ::AuraRouting.Tunables.LevelRequired;
						// NOTES hard coded to have the perk in row 4 (index 3) of the perk tree, as this is where the Druid mod places its perks. This is a temporary solution until a better system is implemented.
						perks[4].push(p);
						result.aura_routing_perkTree <- perks;
						::AuraRouting.Mod.Debug.printLog("[AuraRouting] : perks = " + perks);
						::AuraRouting.Mod.Debug.printLog("[AuraRouting] : result = " + result.aura_routing_perkTree);
						// Debugging the Perks Array
						::AuraRouting.Mod.Debug.printLog("[AuraRouting] Checking Perks Array Structure:");
						foreach (idx, row in perks) {
							::AuraRouting.Mod.Debug.printLog(" - Row " + idx + " has " + row.len() + " elements.");
						}

						// Debugging your new perk object 'p'
						if (p != null) {
							::AuraRouting.Mod.Debug.printLog("[AuraRouting] Perk ID: " + p.m.ID);
							::AuraRouting.Mod.Debug.printLog("[AuraRouting] Perk Icon Path: " + (("Icon" in p.m) ? p.m.Icon : "MISSING"));
						} else {
							::AuraRouting.Mod.Debug.printLog("[AuraRouting] ERROR: Perk 'p' is null!");
						}
					}
				}
			}
			return result;
		}
	});
});

::AuraRouting.grantPerkIfEligible <- function(_actor)
{
	if (_actor == null) return;

	try
	{
		if (!("getSkills" in _actor)) return;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] getSkills is available for " + _actor.getName());
		local skills = _actor.getSkills();
		if (skills == null) return;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] getSkills not null for " + _actor.getName());
		if (_actor.getLevel() < ::AuraRouting.Tunables.LevelRequired) return;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] Level is sufficient for " + _actor.getName());
		if (skills.hasSkill("perk.aura_routing")) return;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] No existing aura_routing perk for " + _actor.getName());

		::AuraRouting.Mod.Debug.printLog("[AuraRouting] Granting perk to " + _actor.getName() + " at level " + _actor.getLevel());
		skills.add(::new("scripts/skills/perks/perk_aura_routing"));
	}
	catch (e)
	{
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] failed to grant perk: " + e);
	}
};