this.aura_routing_perk <- this.inherit("scripts/skills/skill", {
	function create()
	{
		this.m.ID = "perk.aura_routing";
		this.m.Name = "Aura Routing";
		this.m.Description = "Unlocks the Aura Routing active skill.";
		this.m.Icon = "ui/aura/aura_pulse.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsSerialized = true;
		this.m.IsStacking = false;
	},

	function onAdded()
	{
		local c = this.getContainer();
		if (c != null && !c.hasSkill("actives.aura_routing"))
			c.add(::new("scripts/skills/actives/aura_routing_skill"));
	},

	function onRemoved()
	{
		local c = this.getContainer();
		if (c != null && c.hasSkill("actives.aura_routing"))
			c.removeByID("actives.aura_routing");
	}
});
