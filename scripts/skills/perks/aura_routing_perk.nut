this.aura_routing_perk <- this.inherit("scripts/skills/skill", {
	function create()
	{
		this.m.ID = "perk.aura_routing";
		local perk = ::Const.Perks.LookupMap[this.m.ID];
        this.m.Name = perk.Name;
        this.m.Icon = perk.Icon;
        this.m.IconDisabled = perk.IconDisabled;

        this.m.Type = ::Const.SkillType.Perk | ::Const.SkillType.StatusEffect;
        this.m.Order = ::Const.SkillOrder.Perk;
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
