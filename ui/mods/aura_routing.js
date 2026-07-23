var AuraRouting = {};

AuraRouting.CharacterScreenPerksModule_loadPerkTreesWithBrotherData
	= CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData;
	
CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData = function (_brother)
{
	if (_brother.aura_routing_perkTree)
	{
		this.resetPerkTree(this.mPerkTree);
		this.onPerkTreeLoaded(null, _brother.aura_routing_perkTree);
		this.mPerkTree.auraRoutingTree = true;
	}
	else if (this.mPerkTree && this.mPerkTree.auraRoutingTree)
	{
		this.onPerkTreeLoaded(null, this.mDataSource.getPerkTrees());
	}

	AuraRouting.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
};

AuraRouting.CharacterScreenPerksModule_isPerkUnlockable
	= CharacterScreenPerksModule.prototype.isPerkUnlockable;
CharacterScreenPerksModule.prototype.isPerkUnlockable = function (_perk)
{
	if (_perk.aura_routing_locked)
		return false;

	return AuraRouting.CharacterScreenPerksModule_isPerkUnlockable.call(this, _perk);
};
