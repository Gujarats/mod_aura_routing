//create perk that grants the aura routing active skill when added to a character
this.aura_routing_perk <- this.inherit("scripts/skills/skill", {
	m = {}
	function create()
	{
		this.m.ID = "perk.aura_routing";
		local perk = ::Const.Perks.LookupMap[this.m.ID];
        this.m.Name = perk.Name;
        this.m.Description = perk.Tooltip;
        this.m.Icon = perk.Icon;
        this.m.IconDisabled = perk.IconDisabled;

        this.m.Type = this.Const.SkillType.Perk;
        this.m.Order = this.Const.SkillOrder.Perk;
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
