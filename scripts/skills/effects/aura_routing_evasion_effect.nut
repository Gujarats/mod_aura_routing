this.aura_routing_evasion_effect <- this.inherit("scripts/skills/skill", {
	m = {
		MeleeDefenseBonus = 0,
		RangedDefenseBonus = 0,
		IsFallbackEyesVisible = false,
		PreviousPermanentInjury4Brush = null,
		PreviousPermanentInjury4Visible = false,
		PreviousPermanentInjury4Alpha = 255,
		PulseToken = 0,
		PulseStartMs = 0,
		PulsePeriodMs = 1200,
		PulseMinAlpha = 90,
		PulseMaxAlpha = 255,
		PulseTickMs = 60
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

	function rememberPermanentInjury4State( _sprite )
	{
		this.m.PreviousPermanentInjury4Visible = _sprite.Visible;
		this.m.PreviousPermanentInjury4Alpha = _sprite.Alpha;

		local brush = _sprite.getBrush();
		this.m.PreviousPermanentInjury4Brush = brush == null ? null : brush.Name;
	}

	function showFallbackEyes()
	{
		local actor = this.getContainer().getActor();
		if (actor == null) return;

		if (!actor.hasSprite("permanent_injury_4"))
		{
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: missing permanent_injury_4 sprite");
			return;
		}

		if (!this.doesBrushExist("zombie_rage_eyes"))
		{
			::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: missing zombie_rage_eyes brush");
			return;
		}

		local sprite = actor.getSprite("permanent_injury_4");
		this.rememberPermanentInjury4State(sprite);

		::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: applying zombie_rage_eyes");
		sprite.Visible = true;
		sprite.setBrush("zombie_rage_eyes");

		if (actor.isHiddenToPlayer())
		{
			sprite.Alpha = 255;
		}
		else
		{
			sprite.Alpha = 0;
			sprite.fadeIn(1500);
		}

		this.m.IsFallbackEyesVisible = true;
		actor.setDirty(true);
		this.startFallbackEyesPulse();
	}

	function fallbackEyesPulseTick( _ctx )
	{
		if (this.m.PulseToken != _ctx.token) return;
		if (!this.m.IsFallbackEyesVisible) return;
		if (this.getContainer() == null) return;

		local actor = this.getContainer().getActor();
		if (actor == null || !actor.isAlive() || !actor.hasSprite("permanent_injury_4")) return;

		local sprite = actor.getSprite("permanent_injury_4");
		if (!sprite.Visible) return;

		local elapsed = ::Time.getRealTime() * 1000.0 - this.m.PulseStartMs;
		local cycles = elapsed / this.m.PulsePeriodMs.tofloat();
		local phase = cycles - ::Math.floor(cycles);
		local tri = phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0;
		local smooth = tri * tri * (3.0 - 2.0 * tri);
		local alpha = this.m.PulseMinAlpha + (this.m.PulseMaxAlpha - this.m.PulseMinAlpha) * smooth;
		sprite.Alpha = alpha.tointeger();

		::Time.scheduleEvent(::TimeUnit.Real, this.m.PulseTickMs, this.fallbackEyesPulseTick.bindenv(this), _ctx);
	}

	function startFallbackEyesPulse()
	{
		this.m.PulseToken = this.m.PulseToken + 1;
		this.m.PulseStartMs = ::Time.getRealTime() * 1000.0;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: pulse started");

		local ctx = {
			token = this.m.PulseToken
		};
		::Time.scheduleEvent(::TimeUnit.Real, this.m.PulseTickMs, this.fallbackEyesPulseTick.bindenv(this), ctx);
	}

	function stopFallbackEyesPulse()
	{
		this.m.PulseToken = this.m.PulseToken + 1;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: pulse stopped");
	}

	function hideFallbackEyes()
	{
		if (!this.m.IsFallbackEyesVisible) return;
		this.stopFallbackEyesPulse();
		if (this.getContainer() == null) return;

		local actor = this.getContainer().getActor();
		if (actor == null || !actor.hasSprite("permanent_injury_4")) return;

		local sprite = actor.getSprite("permanent_injury_4");

		if (this.m.PreviousPermanentInjury4Brush != null)
		{
			sprite.setBrush(this.m.PreviousPermanentInjury4Brush);
		}
		else
		{
			sprite.resetBrush();
		}

		sprite.Alpha = this.m.PreviousPermanentInjury4Alpha;
		sprite.Visible = this.m.PreviousPermanentInjury4Visible;

		if (!this.m.PreviousPermanentInjury4Visible && !actor.isHiddenToPlayer())
		{
			sprite.setBrush("zombie_rage_eyes");
			sprite.Alpha = 255;
			sprite.Visible = true;
			sprite.fadeOutAndHide(1500);
		}

		this.m.IsFallbackEyesVisible = false;
		::AuraRouting.Mod.Debug.printLog("[AuraRouting] Aura Fallback Eyes: removed");
		actor.setDirty(true);
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

	function onAdded()
	{
		this.showFallbackEyes();
	}

	function onTurnStart()
	{
		this.removeSelf();
	}

	function onRemoved()
	{
		this.hideFallbackEyes();
	}

	function onCombatFinished()
	{
		this.hideFallbackEyes();
	}
});
