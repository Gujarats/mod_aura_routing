this.aura_routing_skill <- ::inherit("scripts/skills/skill", {
    m = {
        Charges = 0,
        MaxCharges = 0
    },

    function create()
    {
        this.m.ID = "actives.aura_routing";
        this.m.Name = "Aura Routing";
        this.m.Description = "Unleash a panic aura that forces up to 3 nearby enemies into Fleeing.";
        this.m.Icon = "aura/aura_routing_skill.png";
        this.m.IconDisabled = "aura/aura_routing_skill_sw.png";
        this.m.Overlay = "aura_routing_effect"; // TODO : need to create unique Overlay so it does not uses the vanilla icon
        this.m.SoundOnUse = ["sounds/combat/indomitable_01.wav"];

        this.m.Type = this.Const.SkillType.Active;
        this.m.Order = this.Const.SkillOrder.Offensive;
        this.m.IsSerialized = true;
        this.m.IsActive = true;
        this.m.IsTargeted = true;
        this.m.IsAttack = true; // MUST be true for AOE targeting logic to function[cite: 2]
        this.m.IsStacking = false;

        this.m.ActionPointCost = 5;
        this.m.FatigueCost = 25;
        this.m.MinRange = 1;
        this.m.MaxRange = 1;

        this.m.MaxCharges = ::AuraRouting.Mod.ModSettings.getSetting("UsesPerBattle").getValue();
        this.m.Charges = this.m.MaxCharges;
    }

    function isUsable()
    {
        local isTrue = this.m.Charges > 0 && this.m.Container.getActor().getActionPoints() >= this.m.ActionPointCost;
        ::AuraRouting.Mod.Debug.printLog("[AuraRouting] isTrue : " + isTrue + " | Charges: " + this.m.Charges + " | MaxCharges: " + this.m.MaxCharges + " | ActionPoints: " + this.m.Container.getActor().getActionPoints() + " | ActionPointCost: " + this.m.ActionPointCost);
        return isTrue;
    }

    function onUse( _user, _targetTile )
    {
        this.spawnAttackEffect(_targetTile, this.Const.Tactical.AttackEffectLash);
        local ownTile = _user.getTile();
        local dir = ownTile.getDirectionTo(_targetTile);
        local tiles = [ _targetTile ];

        // 1. Rebuild the 3-tile arc list
        for (local i = 1; i < 3; i++)
        {
            local nextDir = (dir - i) % this.Const.Direction.COUNT;
            if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
            if (ownTile.hasNextTile(nextDir))
                tiles.push(ownTile.getNextTile(nextDir));
        }

        // 2. Safety check: Ensure at least one target is an enemy
        local hasEnemy = false;
        foreach (tile in tiles)
        {
            if (tile.IsOccupiedByActor)
            {
                local entity = tile.getEntity();
                if (entity != null && entity.isAlive() && !entity.isAlliedWith(_user))
                {
                    hasEnemy = true;
                    break;
                }
            }
        }

        if (!hasEnemy) return false;

        // Visual cue: a wide aura burst centred on the user.
		try
		{
			if (this.doesBrushExist("aura_body_glow_v2"))
			{
                ::AuraRouting.Mod.Debug.printLog("[AuraRouting]: found brush : aura_body_glow_v2")
				this.Tactical.spawnSpriteEffect("aura_body_glow_v2",
					this.createColor("#e63f33"), ownTile,
					0, 30, 1.4, 2.4, 100, 60, 400);
			}
		}
		catch (e) {}

        // 3. Execution: Apply effect to all valid enemies in the arc[cite: 1, 2, 3]
        foreach (tile in tiles)
        {
            if (tile.IsOccupiedByActor)
            {
                local entity = tile.getEntity();
                if (entity != null && entity.isAlive() && !entity.isAlliedWith(_user))
                {
                    this.spawnFearBurst(_user.getTile(), tile);
                    this.Tactical.getShaker().shake(entity, _user.getTile(), 4);
                    entity.setMoraleState(this.Const.MoraleState.Fleeing);
                }
            }
        }

        this.m.Charges = this.Math.max(0, this.m.Charges - 1);
        return true;
    }

    function spawnFearBurst( _originTile, _targetTile )
    {
        if (!this.doesBrushExist("sand_dust_01"))
        {
            ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Missing particle brush: sand_dust_01");
            return;
        }

        local direction = _originTile.getDirectionTo(_targetTile);
        local directionVectors = [
            this.createVec(0.0, -1.0), this.createVec(0.85, -0.5),
            this.createVec(0.85, 0.5), this.createVec(0.0, 1.0),
            this.createVec(-0.85, 0.5), this.createVec(-0.85, -0.5)
        ];
        local burstDirection = directionVectors[direction];
        local effect = {
            Delay = 0,
            Quantity = 16,
            LifeTimeQuantity = 16,
            SpawnRate = 400,
            Brushes = ["sand_dust_01"],
            Stages = [
                {
                    LifeTimeMin = 0.1,
                    LifeTimeMax = 0.2,
                    ColorMin = this.createColor("e65c1a00"),
                    ColorMax = this.createColor("ffb34700"),
                    ScaleMin = 0.5,
                    ScaleMax = 0.75,
                    RotationMin = 0,
                    RotationMax = 359,
                    VelocityMin = 70,
                    VelocityMax = 115,
                    DirectionMin = burstDirection,
                    DirectionMax = burstDirection,
                    SpawnOffsetMin = this.createVec(-25, -15),
                    SpawnOffsetMax = this.createVec(25, 20)
                },
                {
                    LifeTimeMin = 0.75,
                    LifeTimeMax = 1.0,
                    ColorMin = this.createColor("e65c1acc"),
                    ColorMax = this.createColor("ffb347aa"),
                    ScaleMin = 0.55,
                    ScaleMax = 0.9,
                    VelocityMin = 15,
                    VelocityMax = 35,
                    ForceMin = this.createVec(0, 0),
                    ForceMax = this.createVec(0, 0)
                },
                {
                    LifeTimeMin = 0.1,
                    LifeTimeMax = 0.2,
                    ColorMin = this.createColor("e65c1a00"),
                    ColorMax = this.createColor("ffb34700"),
                    ScaleMin = 0.75,
                    ScaleMax = 1.0,
                    VelocityMin = 0,
                    VelocityMax = 0,
                    ForceMin = this.createVec(0, -100),
                    ForceMax = this.createVec(0, -100)
                }
            ]
        };

        try
        {
            this.Tactical.spawnParticleEffect(false, effect.Brushes, _targetTile, effect.Delay, effect.Quantity, effect.LifeTimeQuantity, effect.SpawnRate, effect.Stages, this.createVec(0, 70));
        }
        catch (e)
        {
            ::AuraRouting.Mod.Debug.printLog("[AuraRouting] Fear burst failed: " + e);
        }
    }

    function onTargetSelected( _targetTile )
	{
		local ownTile = this.m.Container.getActor().getTile();
		local dir = ownTile.getDirectionTo(_targetTile);
		this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, _targetTile, _targetTile.Pos.X, _targetTile.Pos.Y);
		local nextDir = dir - 1 >= 0 ? dir - 1 : this.Const.Direction.COUNT - 1;

		if (ownTile.hasNextTile(nextDir))
		{
			local nextTile = ownTile.getNextTile(nextDir);

			if (this.Math.abs(nextTile.Level - ownTile.Level) <= 1)
			{
				this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, nextTile, nextTile.Pos.X, nextTile.Pos.Y);
			}
		}

		nextDir = nextDir - 1 >= 0 ? nextDir - 1 : this.Const.Direction.COUNT - 1;

		if (ownTile.hasNextTile(nextDir))
		{
			local nextTile = ownTile.getNextTile(nextDir);

			if (this.Math.abs(nextTile.Level - ownTile.Level) <= 1)
			{
				this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, nextTile, nextTile.Pos.X, nextTile.Pos.Y);
			}
		}
	}

    // we can use hit chance to make this skill not overpowered,
    // or find a way to make this skill usage once per batlle regardless who uses first.
    function isUsingHitchance()
    {
        return false;
    }

    function getTooltip()
	{
		// local ret = this.getDefaultTooltip();
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
                text = "Can hit up to 3 targets"
            },
            {
                id = 6,
                type = "text",
                icon = "ui/icons/hitchance.png",
                text = "Has 100% chance to hit"
            }
		];

		return ret;
	}

    // Retained helper functions[cite: 1]
    function onCombatStarted() { this.m.Charges = ::AuraRouting.Mod.ModSettings.getSetting("UsesPerBattle").getValue(); }
    function onCombatFinished() { this.onCombatStarted(); }
});
