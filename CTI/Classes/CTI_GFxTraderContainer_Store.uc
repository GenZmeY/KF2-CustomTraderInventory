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

	if (Has9mmGun())
	{
		if ((Item.ClassName == 'KFWeap_HRG_93r' || Item.ClassName == 'KFWeap_HRG_93r_Dual'))
			return true;
	}
	else
	{
		if ((Item.ClassName == 'KFWeap_Pistol_9mm' || Item.ClassName == 'KFWeap_Pistol_Dual9mm'))
			return true;
	}

	return false;
}

defaultproperties
{

}
