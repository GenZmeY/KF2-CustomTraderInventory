class Helper extends Object;

private delegate int ByPrice(class<KFWeaponDefinition> A, class<KFWeaponDefinition> B)
{
	return A.default.BuyPrice > B.default.BuyPrice ? -1 : 0;
}

public static simulated function ModifyTrader(
	KFGameReplicationInfo KFGRI,
	Array<class<KFWeaponDefinition> > RemoveItems,
	Array<class<KFWeaponDefinition> > AddItems,
	bool ReplaceMode)
{
	local KFGFxObject_TraderItems TraderItems;
	local STraderItem Item;
	local class<KFWeaponDefinition> WeapDef;
	local Array<class<KFWeaponDefinition> > WeapDefs;
	local int Index;
	local int MaxItemID;
	
	if (KFGRI == None) return;
	
	TraderItems = KFGFxObject_TraderItems(DynamicLoadObject(KFGRI.TraderItemsPath, class'KFGFxObject_TraderItems'));
	
	if (!ReplaceMode)
	{
		foreach TraderItems.SaleItems(Item)
		{
			if (Item.WeaponDef != None && RemoveItems.Find(Item.WeaponDef) == INDEX_NONE)
			{
				WeapDefs.AddItem(Item.WeaponDef);
			}
		}
	}
	
	for (Index = 0; Index < AddItems.Length; Index++)
		WeapDefs.AddItem(AddItems[Index]);
	
	WeapDefs.Sort(ByPrice);
	
	TraderItems.SaleItems.Length = 0;
	MaxItemID = 0;
	foreach WeapDefs(WeapDef)
	{
		Item.WeaponDef = WeapDef;
		Item.ItemID = ++MaxItemID;
		TraderItems.SaleItems.AddItem(Item);
	}

	TraderItems.SetItemsInfo(TraderItems.SaleItems);
	
	KFGRI.TraderItems = TraderItems;
}

defaultproperties
{
	
}
