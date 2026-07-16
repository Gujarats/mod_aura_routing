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
        this.m.SoundOnUse = ["sounds/combat/indomitable_01.wav"];

        this.m.Type = this.Const.SkillType.Active;
        this.m.Order = this.Const.SkillOrder.Any + 75;
        this.m.IsSerialized = true;
        this.m.IsActive = true;
        this.m.IsTargeted = true; // Required for target selection
        this.m.IsStacking = false;
        this.m.IsAttack = false;

        this.m.ActionPointCost = 5;
        this.m.FatigueCost = 25;
        this.m.MinRange = 1;
        this.m.MaxRange = 1;

        this.m.MaxCharges = this.getConfiguredCharges();
        this.m.Charges = this.m.MaxCharges;
    }

    function getTooltip()
    {
        local ret = this.getDefaultUtilityTooltip();
        ret.push({ id = 10, type = "text", icon = "ui/icons/bravery.png", text = "Forces up to 3 enemies in melee range into Fleeing." });
        ret.push({ id = 11, type = "text", icon = "ui/icons/special.png", text = "Uses left: " + this.m.Charges + " / " + this.m.MaxCharges });
        return ret;
    }

    // Highlights the 3 tiles that will be affected when hovering over a target
    function onTargetSelected( _targetTile )
    {
        local ownTile = this.m.Container.getActor().getTile();
        local dir = ownTile.getDirectionTo(_targetTile);
        this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, _targetTile, _targetTile.Pos.X, _targetTile.Pos.Y);

        for (local i = 1; i < 3; i++)
        {
            local nextDir = (dir - i) % this.Const.Direction.COUNT;
            if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
            if (ownTile.hasNextTile(nextDir))
                this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, ownTile.getNextTile(nextDir), 0, 0);
        }
    }

    function onUse( _user, _targetTile )
    {
        local ownTile = _user.getTile();
        local dir = ownTile.getDirectionTo(_targetTile);
        local tiles = [ _targetTile ];

        // Collect the 3 tiles in the arc
        for (local i = 1; i < 3; i++)
        {
            local nextDir = (dir - i) % this.Const.Direction.COUNT;
            if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
            if (ownTile.hasNextTile(nextDir))
                tiles.push(ownTile.getNextTile(nextDir));
        }

        // Apply effect
        foreach (tile in tiles)
        {
            if (tile.IsOccupiedByActor)
            {
                local entity = tile.getEntity();
                if (entity != null && entity.isAlive() && !entity.isAlliedWith(_user))
                    entity.setMoraleState(this.Const.MoraleState.Fleeing);
            }
        }

        this.m.Charges = this.Math.max(0, this.m.Charges - 1);
        return true;
    }

    function getConfiguredCharges() { /* ... kept as before ... */ return 1; }
    function onCombatStarted() { this.m.Charges = this.getConfiguredCharges(); }
    function onCombatFinished() { this.onCombatStarted(); }
});