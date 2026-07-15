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

::AuraRouting.grantPerkIfEligible <- function(_actor)
{
	if (_actor == null) return;

	try
	{
		if (!("getSkills" in _actor)) return;
		local skills = _actor.getSkills();
		if (skills == null) return;
		if (_actor.getLevel() < ::AuraRouting.Tunables.LevelRequired) return;
		if (skills.hasSkill("perk.aura_routing")) return;

		skills.add(::new("scripts/skills/perks/perk_aura_routing"));
	}
	catch (e)
	{
		::logError("Aura Routing: failed to grant perk - " + e);
	}
};

local mod = ::Hooks.register(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
mod.require("vanilla", "mod_msu >= 1.8.0", "mod_modern_hooks");

mod.queue(">mod_msu", function()
{
	::AuraRouting.MSU <- ::MSU.Class.Mod(::AuraRouting.ID, ::AuraRouting.Version, ::AuraRouting.Name);
	try
	{
		::AuraRouting.registerSettings();
	}
	catch (e)
	{
		::logError("Aura Routing: failed to initialize MSU settings - " + e);
	}

	::Hooks.registerJS("ui/mods/aura_routing.js");

	mod.hook("scripts/entity/tactical/actor", function(q)
	{
		q.addXP = @(__original) function(_xp, _scale = true)
		{
			local ret = __original(_xp, _scale);
			::AuraRouting.grantPerkIfEligible(this);
			return ret;
		}
	});

	mod.hook("scripts/entity/tactical/player", function(q)
	{
		q.onHired = @(__original) function()
		{
			local ret = __original();
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
			::AuraRouting.grantPerkIfEligible(actor);
			return ret;
		}
	});

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
					local showTree = skills.hasSkill("perk.aura_routing") || _entity.getLevel() >= ::AuraRouting.Tunables.LevelRequired;
					if (showTree)
					{
						local perks = ::Const.Perks.Perks.map(@(row) clone row);
						local p = ::new("scripts/skills/perks/perk_aura_routing");
						p.aura_routing_locked <- _entity.getLevel() < ::AuraRouting.Tunables.LevelRequired;
						perks[3].push(p);
						result.aura_routing_perkTree <- perks;
					}
				}
			}
			return result;
		}
	});
});



