class CTI_GFxTraderContainer_Store extends KFGFxTraderContainer_Store;

function bool IsItemFiltered(STraderItem Item, optional bool bDebug)
{
	if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.ClassName))
		return true;
	if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.DualClassName))
		return true;
	if (!KFPC.GetPurchaseHelper().IsSellable(Item))
		return true;
	if (Item.WeaponDef.default.PlatformRestriction != PR_All && class'KFUnlockManager'.static.IsPlatformRestricted(Item.WeaponDef.default.PlatformRestriction))
		return true;

	return false;
}

defaultproperties
{

}
