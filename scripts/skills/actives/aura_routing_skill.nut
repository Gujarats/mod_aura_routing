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
        this.m.Icon = "aura/aura_supreme_perk.png";
        this.m.IconDisabled = "aura/aura_supreme_perk_sw.png";
        this.m.Overlay = "active_06"; // Added overlay to support UI icons
        this.m.SoundOnUse = ["sounds/combat/indomitable_01.wav"];

        this.m.Type = this.Const.SkillType.Active;
        this.m.Order = this.Const.SkillOrder.OffensiveTargeted; // Updated order for targeting
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

        // 3. Execution: Apply effect to all valid enemies in the arc[cite: 1, 2, 3]
        foreach (tile in tiles)
        {
            if (tile.IsOccupiedByActor)
            {
                local entity = tile.getEntity();
                if (entity != null && entity.isAlive() && !entity.isAlliedWith(_user))
                {
                    entity.setMoraleState(this.Const.MoraleState.Fleeing);
                }
            }
        }

        this.m.Charges = this.Math.max(0, this.m.Charges - 1);
        return true;
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