class Trader extends Object
	abstract;

// Bug:
// The wrong weapon is purchased if the index is greater than 256 😡
// Some greedy guy saved 3 bytes for no reason again
const ITEMS_LIMIT = 256;

private delegate int ByPrice(class<KFWeaponDefinition> A, class<KFWeaponDefinition> B)
{
	return A.default.BuyPrice > B.default.BuyPrice ? -1 : 0;
}

public static function KFGFxObject_TraderItems GetTraderItems(optional KFGameReplicationInfo KFGRI = None, optional E_LogLevel LogLevel = LL_Trace)
{
	local String TraderItemsPath;

	if (KFGRI == None)
	{
		TraderItemsPath = class'KFGameReplicationInfo'.default.TraderItemsPath;
	}
	else
	{
		TraderItemsPath = KFGRI.TraderItemsPath;
	}

	return KFGFxObject_TraderItems(DynamicLoadObject(TraderItemsPath, class'KFGFxObject_TraderItems'));
}

public static function Array<class<KFWeaponDefinition> > GetTraderWeapDefs(optional KFGameReplicationInfo KFGRI = None, optional E_LogLevel LogLevel = LL_Trace)
{
	local Array<class<KFWeaponDefinition> > KFWeapDefs;
	local KFGFxObject_TraderItems TraderItems;
	local STraderItem Item;

	TraderItems = GetTraderItems(KFGRI, LogLevel);

	foreach TraderItems.SaleItems(Item)
	{
		if (Item.WeaponDef != None)
		{
			KFWeapDefs.AddItem(Item.WeaponDef);
		}
	}

	return KFWeapDefs;
}

public static function Array<class<KFWeapon> > GetTraderWeapons(optional KFGameReplicationInfo KFGRI = None, optional E_LogLevel LogLevel = LL_Trace)
{
	local Array<class<KFWeapon> > KFWeapons;
	local class<KFWeapon> KFWeapon;
	local KFGFxObject_TraderItems TraderItems;
	local STraderItem Item;

	TraderItems = GetTraderItems(KFGRI, LogLevel);

	foreach TraderItems.SaleItems(Item)
	{
		if (Item.WeaponDef != None)
		{
			KFWeapon = class<KFWeapon> (DynamicLoadObject(Item.WeaponDef.default.WeaponClassPath, class'Class'));
			if (KFWeapon != None)
			{
				KFWeapons.AddItem(KFWeapon);
			}
		}
	}

	return KFWeapons;
}

public static function Array<class<KFWeaponDefinition> > GetTraderWeapDefsDLC(KFGameReplicationInfo KFGRI, E_LogLevel LogLevel)
{
	local KFGFxObject_TraderItems TraderItems;
	local STraderItem Item;
	local Array<class<KFWeaponDefinition> > WeapDefs;

	`Log_TraceStatic();

	TraderItems = GetTraderItems(KFGRI, LogLevel);

	foreach TraderItems.SaleItems(Item)
	{
		if (Item.WeaponDef != None && Item.WeaponDef.default.SharedUnlockId != SCU_None)
		{
			WeapDefs.AddItem(Item.WeaponDef);
		}
	}

	return WeapDefs;
}

public static simulated function ModifyTrader(
	KFGameReplicationInfo KFGRI,
	const out Array<class<KFWeaponDefinition> > RemoveItems,
	const out Array<class<KFWeaponDefinition> > AddItems,
	bool ReplaceMode,
	bool RemoveHRG,
	bool RemoveDLC,
	bool bDisableItemLimitCheck,
	E_LogLevel LogLevel)
{
	local KFGFxObject_TraderItems TraderItems;
	local STraderItem Item;
	local Array<class<KFWeaponDefinition> > WeapDefs;
	local int Index;

	`Log_TraceStatic();

	TraderItems = GetTraderItems(KFGRI, LogLevel);

	if (!ReplaceMode)
	{
		foreach TraderItems.SaleItems(Item)
		{
			if (Item.WeaponDef != None
			&& RemoveItems.Find(Item.WeaponDef) == INDEX_NONE
			&& (!RemoveHRG || (RemoveHRG && InStr(Item.WeaponDef, "_HRG", true) == INDEX_NONE))
			&& (!RemoveDLC || (RemoveDLC && Item.WeaponDef.default.SharedUnlockId == SCU_None))
			&& WeaponClassIsUnique(Item.WeaponDef.default.WeaponClassPath, AddItems, LogLevel))
			{
				WeapDefs.AddItem(Item.WeaponDef);
			}
		}
	}

	for (Index = 0; Index < AddItems.Length; ++Index)
	{
		WeapDefs.AddItem(AddItems[Index]);
	}

	WeapDefs.Sort(ByPrice);

	if (!bDisableItemLimitCheck && WeapDefs.Length > ITEMS_LIMIT)
	{
		`Log_Warn("The total number of items has reached the limit (" $ ITEMS_LIMIT $ ")," @ (WeapDefs.Length - ITEMS_LIMIT) @ "items will not be added.");
		`Log_Warn("Excluded items:");
		for (Index = ITEMS_LIMIT; Index < WeapDefs.Length; ++Index)
		{
			`Log_Warn("[" $ Index + 1 $ "]" @ String(WeapDefs[Index]));
		}
		WeapDefs.Length = ITEMS_LIMIT;
	}

	OverwriteTraderItems(KFGRI, WeapDefs, LogLevel);
}

public static simulated function OverwriteTraderItems(
	KFGameReplicationInfo KFGRI,
	const out Array<class<KFWeaponDefinition> > WeapDefs,
	E_LogLevel LogLevel)
{
	local KFGFxObject_TraderItems TraderItems;
	local STraderItem Item;
	local class<KFWeaponDefinition> WeapDef;
	local int MaxItemID;

	`Log_TraceStatic();

	TraderItems = GetTraderItems(KFGRI, LogLevel);

	TraderItems.SaleItems.Length = 0;
	MaxItemID = 0;

	`Log_Debug("Trader Items:");
	foreach WeapDefs(WeapDef)
	{
		Item.WeaponDef = WeapDef;
		Item.ItemID = MaxItemID++;
		TraderItems.SaleItems.AddItem(Item);
		`Log_Debug("[" $ MaxItemID $ "]" @ String(WeapDef));
	}

	TraderItems.SetItemsInfo(TraderItems.SaleItems);

	KFGRI.TraderItems = TraderItems;
}

private static function bool WeaponClassIsUnique(String WeaponClassPath, const out Array<class<KFWeaponDefinition> > WeapDefs, E_LogLevel LogLevel)
{
	local class<KFWeaponDefinition> WeapDef;

	`Log_TraceStatic();

	foreach WeapDefs(WeapDef)
	{
		if (WeapDef.default.WeaponClassPath == WeaponClassPath)
		{
			return false;
		}
	}

	return true;
}

defaultproperties
{

}
