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

        this.m.MaxCharges = this.getConfiguredCharges();
        this.m.Charges = this.m.MaxCharges;
    }

    // Add this helper to check if the move is valid (hits at least one enemy)
    function isTargetingEnemy( _user, _targetTile )
    {
        local ownTile = _user.getTile();
        local dir = ownTile.getDirectionTo(_targetTile);
        local tiles = [ _targetTile ];

        for (local i = 1; i < 3; i++)
        {
            local nextDir = (dir - i) % this.Const.Direction.COUNT;
            if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
            if (ownTile.hasNextTile(nextDir))
                tiles.push(ownTile.getNextTile(nextDir));
        }

        foreach (tile in tiles)
        {
            if (tile.IsOccupiedByActor)
            {
                local entity = tile.getEntity();
                // Return true as soon as we find one enemy
                if (entity != null && entity.isAlive() && !entity.isAlliedWith(_user))
                    return true;
            }
        }
        return false;
    }

    // Modify onUse to perform this check
    function onUse( _user, _targetTile )
    {
        // Forbid use if no enemies are targeted
        if (!this.isTargetingEnemy(_user, _targetTile))
        {
            return false;
        }

        local ownTile = _user.getTile();
        local dir = ownTile.getDirectionTo(_targetTile);
        local tiles = [ _targetTile ];

        for (local i = 1; i < 3; i++)
        {
            local nextDir = (dir - i) % this.Const.Direction.COUNT;
            if (nextDir < 0) nextDir += this.Const.Direction.COUNT;
            if (ownTile.hasNextTile(nextDir))
                tiles.push(ownTile.getNextTile(nextDir));
        }

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

    // Retained helper functions[cite: 1]
    function getConfiguredCharges() { return 1; }
    function onCombatStarted() { this.m.Charges = this.getConfiguredCharges(); }
    function onCombatFinished() { this.onCombatStarted(); }
});