this.aura_routing_evasion_effect <- this.inherit("scripts/skills/skill", {
	m = {
		MeleeDefenseBonus = 0,
		RangedDefenseBonus = 0
	},

	function create()
	{
		this.m.ID = "effects.aura_routing_evasion";
		this.m.Name = "Aura Evasion";
		this.m.Description = "The unused force of Aura Routing bends incoming attacks aside until this character's next turn.";
		this.m.Icon = "skills/status_effect_08.png";
		this.m.IconMini = "status_effect_08_mini";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsHidden = false;
		this.m.IsRemovedAfterBattle = true;
	}

	function setDefense( _meleeDefense, _rangedDefense )
	{
		this.m.MeleeDefenseBonus = this.Math.max(0, _meleeDefense);
		this.m.RangedDefenseBonus = this.Math.max(0, _rangedDefense);
	}

	function getTooltip()
	{
		local ret = this.skill.getTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/melee_defense.png",
			text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.m.MeleeDefenseBonus + "[/color] Melee Defense until next turn"
		});
		ret.push({
			id = 11,
			type = "text",
			icon = "ui/icons/ranged_defense.png",
			text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + this.m.RangedDefenseBonus + "[/color] Ranged Defense until next turn"
		});
		return ret;
	}

	function onUpdate( _properties )
	{
		_properties.MeleeDefense += this.m.MeleeDefenseBonus;
		_properties.RangedDefense += this.m.RangedDefenseBonus;
	}

	function onTurnStart()
	{
		this.removeSelf();
	}
});
