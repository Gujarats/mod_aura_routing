this.aura_routing_skill <- ::inherit("scripts/skills/skill", {
	m = {
		Charges = 0,
		MaxCharges = 0,
		LastAuraRoutingHits = null,
		LastAuraRoutingMisses = null,
		LastAuraRoutingPreviewTile = null
	},

	function create()
	{
		this.m.ID = "actives.aura_routing";
		this.m.Name = "Aura Routing";
		this.m.Description = "Unleash a panic aura that attacks up to 3 nearby enemies, then pressures landed hits into morale collapse.";
		this.m.Icon = "aura/aura_routing_skill.png";
		this.m.IconDisabled = "aura/aura_routing_skill_sw.png";
		this.m.Overlay = "aura_routing_effect";
		this.m.SoundOnUse = ["sounds/combat/indomitable_01.wav"];

		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = this.Const.SkillOrder.Offensive;
		this.m.IsSerialized = true;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsAttack = true;
		this.m.IsStacking = false;
		this.m.IsUsingHitchance = true;

		this.m.ActionPointCost = 5;
		this.m.FatigueCost = 25;
		this.m.MinRange = 1;
		this.m.MaxRange = 1;
		this.m.MaxLevelDifference = 1;

		this.m.LastAuraRoutingHits = {};
		this.m.LastAuraRoutingMisses = {};
		this.m.LastAuraRoutingPreviewTile = null;
		this.m.MaxCharges = ::AuraRouting.Mod.ModSettings.getSetting("UsesPerBattle").getValue();
		this.m.Charges = this.m.MaxCharges;
	}

	function isUsable()
	{
		if (!this.skill.isUsable()) return false;
		if (this.m.Charges <= 0) return false;
		return this.m.Container.getActor().getActionPoints() >= this.m.ActionPointCost;
	}

	function getEntityHitKey( _entity )
	{
		if (_entity == null) return "";
		return _entity.getID().tostring();
	}

	function onAnySkillUsed( _skill, _targetEntity, _properties )
	{
		if (_skill != this) return;

		local minDamage = ::AuraRouting.Mod.ModSettings.getSetting("AttackDamageMin").getValue();
		local maxDamage = ::AuraRouting.Mod.ModSettings.getSetting("AttackDamageMax").getValue();
		if (maxDamage < minDamage) maxDamage = minDamage;

		this.m.HitChanceBonus = ::AuraRouting.Mod.ModSettings.getSetting("AttackHitChanceBonus").getValue();
		this.m.DirectDamageMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackDirectDamagePct").getValue() / 100.0;
		_properties.DamageRegularMin = minDamage;
		_properties.DamageRegularMax = maxDamage;
		_properties.DamageArmorMult = ::AuraRouting.Mod.ModSettings.getSetting("AttackArmorDamageMultPct").getValue() / 100.0;
	}

	function onTargetHit( _skill, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor )
	{
		if (_skill != this || _targetEntity == null) return;
		this.m.LastAuraRoutingHits[this.getEntityHitKey(_targetEntity)] <- true;
	}

	function onTargetMissed( _skill, _targetEntity )
	{
		if (_skill != this || _targetEntity == null) return;
		this.m.LastAuraRoutingMisses[this.getEntityHitKey(_targetEntity)] <- true;
	}

	function didLastAttackHit( _entity )
	{
		local key = this.getEntityHitKey(_entity);
		return key in this.m.LastAuraRoutingHits;
	}

	function collectArcTiles( _user, _targetTile )
	{
		local ownTile = _user.getTile();
		local dir = ownTile.getDirectionTo(_targetTile);
		local tiles = [ _targetTile ];

		for (local i = 1; i < 3; i++)
		{
			local nextDir = (dir - i) % this.Const.Direction.COUNT;
			if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
			if (ownTile.hasNextTile(nextDir))
			{
				local nextTile = ownTile.getNextTile(nextDir);
				if (this.Math.abs(nextTile.Level - ownTile.Level) <= 1)
				{
					tiles.push(nextTile);
				}
			}
		}

		return tiles;
	}

	function isTileInSelectedArc( _user, _targetTile )
	{
		if (_user == null || _targetTile == null) return false;
		if (this.m.LastAuraRoutingPreviewTile == null) return false;

		local tiles = this.collectArcTiles(_user, this.m.LastAuraRoutingPreviewTile);
		foreach (tile in tiles)
		{
			if (tile.isSameTileAs(_targetTile)) return true;
		}

		return false;
	}

	function getMoraleChangeForPreview( _entity )
	{
		if (_entity == null) return 0;

		local before = _entity.getMoraleState();
		local steps = ::AuraRouting.Mod.ModSettings.getSetting("MoraleDropSteps").getValue();
		local change = -steps;

		if (before == this.Const.MoraleState.Wavering
			&& ::AuraRouting.Mod.ModSettings.getSetting("AllowFleeingOnAlreadyWavering").getValue())
		{
			change = this.Const.MoraleState.Fleeing - before;
		}
		else if (before + change < this.Const.MoraleState.Fleeing)
		{
			change = this.Const.MoraleState.Fleeing - before;
		}

		return change;
	}

	function getMoraleResistChancePct( _user, _entity )
	{
		if (_user == null || _entity == null) return 0;
		if (!this.canAffectMorale(_entity)) return 100;

		local change = this.getMoraleChangeForPreview(_entity);
		if (change >= 0) return 100;

		local properties = _entity.getCurrentProperties();
		local difficulty = -::AuraRouting.Mod.ModSettings.getSetting("MoraleResolvePenalty").getValue();
		difficulty = difficulty * properties.MoraleEffectMult;

		local bravery = (_entity.getBravery() + properties.MoraleCheckBravery[this.Const.MoraleCheckType.MentalAttack]) * properties.MoraleCheckBraveryMult[this.Const.MoraleCheckType.MentalAttack];
		if (bravery > 500) return 100;

		// Mirrors Battle Brothers 1.5.2.3 data_001 actor.checkMorale without rolling or mutating morale.
		local myTile = _entity.getTile();
		local numOpponentsAdjacent = 0;
		local numAlliesAdjacent = 0;
		local threatBonus = 0;

		for (local i = 0; i != 6; i = ++i)
		{
			if (!myTile.hasNextTile(i)) continue;

			local tile = myTile.getNextTile(i);
			if (!tile.IsOccupiedByActor) continue;

			local neighbor = tile.getEntity();
			if (neighbor == null || neighbor.getMoraleState() == this.Const.MoraleState.Fleeing) continue;

			if (neighbor.isAlliedWith(_entity))
			{
				numAlliesAdjacent = ++numAlliesAdjacent;
			}
			else
			{
				numOpponentsAdjacent = ++numOpponentsAdjacent;
				threatBonus = threatBonus + neighbor.getCurrentProperties().Threat;
			}
		}

		local score = bravery + difficulty - numOpponentsAdjacent * this.Const.Morale.OpponentsAdjacentMult + numAlliesAdjacent * this.Const.Morale.AlliesAdjacentMult - threatBonus;
		local baseResist = score;
		if (baseResist < 0) baseResist = 0;
		if (baseResist > 95) baseResist = 95;
		baseResist = baseResist.tointeger();

		local rerollChance = properties.RerollMoraleChance;
		if (rerollChance < 0) rerollChance = 0;
		if (rerollChance > 100) rerollChance = 100;
		rerollChance = rerollChance.tointeger();

		local resistChance = baseResist + (100 - baseResist) * rerollChance * baseResist / 10000;
		if (resistChance < 0) resistChance = 0;
		if (resistChance > 100) resistChance = 100;

		return resistChance.tointeger();
	}

	function getMoraleDropChanceOnHitPct( _user, _entity )
	{
		if (_user == null || _entity == null) return 0;
		if (!this.canAffectMorale(_entity)) return 0;

		local change = this.getMoraleChangeForPreview(_entity);
		if (change >= 0) return 0;

		return 100 - this.getMoraleResistChancePct(_user, _entity);
	}

	function getAuraRoutingTargetTooltip( _targetEntity )
	{
		local ret = [];
		local user = this.m.Container.getActor();
		if (user == null || _targetEntity == null) return ret;
		if (!_targetEntity.isAlive() || _targetEntity.isAlliedWith(user)) return ret;
		if (!this.isTileInSelectedArc(user, _targetEntity.getTile())) return ret;

		if (!this.canAffectMorale(_targetEntity))
		{
			ret.push({
				id = 91001,
				type = "text",
				icon = "ui/icons/bravery.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Immune to Aura Routing morale drop[/color]"
			});
			return ret;
		}

		local dropChance = this.getMoraleDropChanceOnHitPct(user, _targetEntity);
		local resistChance = this.getMoraleResistChancePct(user, _targetEntity);
		local change = -this.getMoraleChangeForPreview(_targetEntity);

		ret.push({
			id = 91001,
			type = "text",
			icon = "ui/icons/bravery.png",
			text = "Morale drop on hit: [color=" + this.Const.UI.Color.PositiveValue + "]" + dropChance + "%[/color]"
		});
		ret.push({
			id = 91002,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Target Resolve: [color=" + this.Const.UI.Color.PositiveValue + "]" + _targetEntity.getBravery() + "[/color], resist chance: [color=" + this.Const.UI.Color.PositiveValue + "]" + resistChance + "%[/color], morale drop: [color=" + this.Const.UI.Color.NegativeValue + "]" + change + " step" + (change == 1 ? "" : "s") + "[/color]"
		});

		return ret;
	}

	function canAffectMorale( _entity )
	{
		if (_entity == null || !_entity.isAlive()) return false;
		if (_entity.isNonCombatant()) return false;
		if (_entity.getMoraleState() == this.Const.MoraleState.Ignore) return false;
		if (_entity.getMoraleState() == this.Const.MoraleState.Fleeing) return false;
		if (!_entity.getCurrentProperties().IsAffectedByLosingHitpoints) return false;

		local flags = _entity.getFlags();
		if (flags != null && flags.has("undead")) return false;

		local skills = _entity.getSkills();
		if (skills != null)
		{
			if (skills.hasSkill("effects.legend_fearless")) return false;
		}

		return true;
	}

	function tryDropMorale( _user, _entity )
	{
		if (!this.didLastAttackHit(_entity)) return false;
		if (!this.canAffectMorale(_entity)) return false;

		local before = _entity.getMoraleState();
		local penalty = ::AuraRouting.Mod.ModSettings.getSetting("MoraleResolvePenalty").getValue();
		local steps = ::AuraRouting.Mod.ModSettings.getSetting("MoraleDropSteps").getValue();
		local change = -steps;

		if (before == this.Const.MoraleState.Wavering
			&& ::AuraRouting.Mod.ModSettings.getSetting("AllowFleeingOnAlreadyWavering").getValue())
		{
			change = this.Const.MoraleState.Fleeing - before;
		}
		else if (before + change < this.Const.MoraleState.Fleeing)
		{
			change = this.Const.MoraleState.Fleeing - before;
		}

		if (change >= 0) return false;

		local changed = _entity.checkMorale(change, -penalty, this.Const.MoraleCheckType.MentalAttack);
		return changed && _entity.getMoraleState() < before;
	}

	function applyFallbackEvasion( _user, _affectedCount )
	{
		local melee = 0;
		local ranged = 0;

		if (_affectedCount == 0)
		{
			melee = ::AuraRouting.Mod.ModSettings.getSetting("NoAffectedMeleeDefense").getValue();
			ranged = ::AuraRouting.Mod.ModSettings.getSetting("NoAffectedRangedDefense").getValue();
		}
		else if (_affectedCount == 1)
		{
			melee = ::AuraRouting.Mod.ModSettings.getSetting("OneAffectedMeleeDefense").getValue();
			ranged = ::AuraRouting.Mod.ModSettings.getSetting("OneAffectedRangedDefense").getValue();
		}
		else if (_affectedCount == 2)
		{
			melee = ::AuraRouting.Mod.ModSettings.getSetting("TwoAffectedMeleeDefense").getValue();
			ranged = ::AuraRouting.Mod.ModSettings.getSetting("TwoAffectedRangedDefense").getValue();
		}

		if (melee <= 0 && ranged <= 0) return false;

		local skills = _user.getSkills();
		skills.removeByID("effects.aura_routing_evasion");
		local effect = ::new("scripts/skills/effects/aura_routing_evasion_effect");
		effect.setDefense(melee, ranged);
		skills.add(effect);
		return true;
	}

	function onUse( _user, _targetTile )
	{
		this.spawnAttackEffect(_targetTile, this.Const.Tactical.AttackEffectLash);
		local ownTile = _user.getTile();
		local tiles = this.collectArcTiles(_user, _targetTile);
		local hasEnemy = false;
		local affectedCount = 0;
		this.m.LastAuraRoutingHits = {};
		this.m.LastAuraRoutingMisses = {};

		try
		{
			if (this.doesBrushExist("aura_body_glow_v2"))
			{
				::AuraRouting.Mod.Debug.printLog("[AuraRouting]: found brush : aura_body_glow_v2");
				this.Tactical.spawnSpriteEffect("aura_body_glow_v2", this.createColor("#e63f33"), ownTile, 0, 30, 1.4, 2.4, 100, 60, 400);
			}
		}
		catch (e) {}

		foreach (tile in tiles)
		{
			if (!tile.IsOccupiedByActor) continue;
			local entity = tile.getEntity();
			if (entity == null || !entity.isAlive() || entity.isAlliedWith(_user)) continue;
			hasEnemy = true;

			this.attackEntity(_user, entity);
			if (this.tryDropMorale(_user, entity))
			{
				affectedCount++;
			}
		}

		if (!hasEnemy) return false;

		local evasionApplied = this.applyFallbackEvasion(_user, affectedCount);
		this.m.Charges = this.Math.max(0, this.m.Charges - 1);
		return affectedCount > 0 || evasionApplied;
	}

	function onTargetSelected( _targetTile )
	{
		local actor = this.m.Container.getActor();
		this.m.LastAuraRoutingPreviewTile = _targetTile;
		local tiles = this.collectArcTiles(actor, _targetTile);

		foreach (tile in tiles)
		{
			this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, tile, tile.Pos.X, tile.Pos.Y);
		}
	}

	function onTargetDeselected()
	{
		this.Tactical.getHighlighter().clearOverlayIcons();
		this.m.LastAuraRoutingPreviewTile = null;
	}

	function getTooltip()
	{
		local ret = [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			},
			{
				id = 3,
				type = "text",
				text = this.getCostString()
			},
			{
				id = 4,
				type = "text",
				icon = "ui/icons/uses.png",
				text = "Uses remaining: " + this.m.Charges + "/" + this.m.MaxCharges
			},
			{
				id = 5,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Can attack up to 3 targets"
			},
			{
				id = 6,
				type = "text",
				icon = "ui/icons/bravery.png",
				text = "Each enemy is attacked normally. Landed hits can damage armor and hitpoints, then force a Resolve check. If few enemies are affected, the user gains temporary defense until their next turn."
			}
		];

		return ret;
	}

	function onCombatStarted()
	{
		this.m.Charges = ::AuraRouting.Mod.ModSettings.getSetting("UsesPerBattle").getValue();
		this.m.MaxCharges = this.m.Charges;
		this.m.LastAuraRoutingHits = {};
		this.m.LastAuraRoutingMisses = {};
		this.m.LastAuraRoutingPreviewTile = null;
	}

	function onCombatFinished()
	{
		this.onCombatStarted();
	}
});
