this.aura_routing_skill <- ::inherit("scripts/skills/actives/root_skill", {
    m = {
        Charges = 0,
        MaxCharges = 0,
        Radius = 3
    },

    function create()
    {
        this.root_skill.create();
        this.m.ID = "actives.aura_routing";
        this.m.Name = "Aura Routing";
        this.m.Description = "Unleash a panic aura that forces nearby enemies into Fleeing.";
        this.m.Icon = "aura/aura_supreme_perk.png";
        this.m.IconDisabled = "aura/aura_supreme_perk_sw.png";
        // this.m.SoundOnUse = [
        //     "sounds/combat/indomitable_01.wav"
        // ];
        // this.m.Type = this.Const.SkillType.Active;
        // this.m.Order = this.Const.SkillOrder.OffensiveTargeted + 220;
        // this.m.IsActive = true;
        // this.m.IsTargeted = false;
        // this.m.IsAttack = false;
        // this.m.IsSerialized = true;
        // this.m.IsStacking = false;
        // this.m.IsIgnoredAsAOO = true;
        // this.m.IsUsingHitchance = false;
        // this.m.ActionPointCost = 3;
        // this.m.FatigueCost = 20;
        // this.m.MinRange = 0;
        // this.m.MaxRange = 0;
        // this.m.Radius = this.getConfiguredRadius();
        // this.m.MaxCharges = this.getConfiguredCharges();
        // this.m.Charges = this.m.MaxCharges;
    }

    function getConfiguredRadius()
    {
        try
        {
            if ("AuraRouting" in ::getroottable() && ::AuraRouting != null && "Tunables" in ::AuraRouting)
                return ::AuraRouting.Tunables.Radius;
        }
        catch (e) {}
        return 3;
    }

    function getConfiguredCharges()
    {
        try
        {
            if ("AuraRouting" in ::getroottable() && ::AuraRouting != null && "Tunables" in ::AuraRouting)
                return ::AuraRouting.Tunables.UsesPerBattle;
        }
        catch (e) {}
        return 1;
    }

    function log(_message)
    {
        try
        {
            if ("AuraRouting" in ::getroottable() && ::AuraRouting != null && "Mod" in ::AuraRouting && "Debug" in ::AuraRouting.Mod)
                ::AuraRouting.Mod.Debug.printLog("[AuraRouting] " + _message);
        }
        catch (e) {}
    }

    function getTooltip()
    {
        local ret = this.getDefaultUtilityTooltip();
        local pos = this.Const.UI.Color.PositiveValue;
        local neg = this.Const.UI.Color.NegativeValue;
        ret.push({
            id = 10, type = "text", icon = "ui/icons/bravery.png",
            text = "Forces every enemy within [color=" + pos + "]" + this.getConfiguredRadius() + "[/color] tiles into [color=" + neg + "]Fleeing[/color]."
        });
        ret.push({
            id = 11, type = "text", icon = "ui/icons/special.png",
            text = "Uses left this battle: [color=" + pos + "]" + this.m.Charges + "[/color] / " + this.m.MaxCharges
        });
        return ret;
    }

    function isUsable()
    {
        if (!this.root_skill.isUsable()) return false;
        if (this.m.Charges <= 0) return false;
        return true;
    }

    function onCombatStarted()
    {
        this.m.Radius = this.getConfiguredRadius();
        this.m.MaxCharges = this.getConfiguredCharges();
        this.m.Charges = this.m.MaxCharges;
        this.log("onCombatStarted(): reset charges=" + this.m.Charges + ", radius=" + this.m.Radius);
    }

    function onUse( _user, _targetTile )
    {
        this.log("onUse(): user=" + (_user != null ? _user.getName() : "null") + ", charges=" + this.m.Charges + ", radius=" + this.m.Radius);
        local userTile = _user.getTile();
        if (userTile == null) return false;

        local radius = this.getConfiguredRadius();
        local enemies = this.getAffectedEnemies(_user, radius);
        foreach (enemy in enemies)
        {
            if (enemy == null || !enemy.isAlive()) continue;
            if (enemy.isAlliedWith(_user)) continue;
            try { enemy.setMoraleState(this.Const.MoraleState.Fleeing); } catch (e) {}
        }

        this.m.Charges = this.Math.max(0, this.m.Charges - 1);

        if ("AuraRouting" in ::getroottable() && ::AuraRouting.Tunables.IsOncePerBattle)
        {
            try
            {
                _user.setActionPoints(0);
                _user.setWaitActionSpent(true);
            }
            catch (e) {}
        }

        this.log("onUse(): completed use, remaining charges=" + this.m.Charges);
        return true;
    }

    function getAffectedEnemies( _user, _radius )
    {
        local origin = _user.getTile();
        if (origin == null) return [];

        local seen = {};
        seen[origin.ID] <- true;
        local frontier = [origin];
        local affected = [];

        for (local depth = 0; depth < _radius; depth = depth + 1)
        {
            local nextFrontier = [];
            foreach (tile in frontier)
            {
                for (local i = 0; i < 6; i = i + 1)
                {
                    if (!tile.hasNextTile(i)) continue;
                    local nextTile = tile.getNextTile(i);
                    if (nextTile == null || nextTile.ID in seen) continue;
                    seen[nextTile.ID] <- true;
                    nextFrontier.push(nextTile);
                    if (!nextTile.IsOccupiedByActor) continue;
                    local enemy = nextTile.getEntity();
                    if (enemy != null && enemy.isAlive() && !enemy.isAlliedWith(_user))
                        affected.push(enemy);
                }
            }
            frontier = nextFrontier;
        }

        this.log("getAffectedEnemies(): found " + affected.len() + " enemies within " + _radius + " radius");
        return affected;
    }

    function onCombatFinished()
    {
        this.log("onCombatFinished(): resetting skill state");
        this.onCombatStarted();
    }
});
