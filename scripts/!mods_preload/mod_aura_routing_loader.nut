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
						foreach (perk in ::Const.Perks.Aura) {
							local p = clone perk;
							delete p.verifyPrerequisites;
							p.druid_blocked <- false;
							perks[perk.Row].push(p);
						}
						result.aura_routing_perkTree <- perks;
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