class AddItems extends Object
	dependson(CTI)
	config(CTI);

var private config Array<String> Item;

public static function InitConfig(int Version, int LatestVersion)
{
	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault();

		default: break;
	}

	if (LatestVersion != Version)
	{
		StaticSaveConfig();
	}
}

private static function ApplyDefault()
{
	default.Item.Length = 0;
	default.Item.AddItem("SomePackage.SomeWeapon");
}

public static function Array<class<KFWeaponDefinition> > Load(E_LogLevel LogLevel)
{
	local Array<class<KFWeaponDefinition> > ItemList;
	local class<KFWeaponDefinition> ItemWeapDef;
	local class<KFWeapon> ItemWeapon;
	local String ItemRaw;
	local int    Line;

	`Log_Info("Load Items to add:");
	foreach default.Item(ItemRaw, Line)
	{
		ItemWeapDef = class<KFWeaponDefinition>(DynamicLoadObject(ItemRaw, class'Class'));
		if (ItemWeapDef == None)
		{
			`Log_Warn("[" $ Line + 1 $ "]" @ "Can't load weapon definition:" @ ItemRaw);
			continue;
		}

		ItemWeapon = class<KFWeapon>(DynamicLoadObject(ItemWeapDef.default.WeaponClassPath, class'Class'));
		if (ItemWeapon == None)
		{
			`Log_Warn("[" $ Line + 1 $ "]" @ "Can't load weapon:" @ ItemWeapDef.default.WeaponClassPath);
			continue;
		}

		if (ItemList.Find(ItemWeapDef) != INDEX_NONE)
		{
			`Log_Warn("[" $ Line + 1 $ "]" @ "Duplicate item:" @ ItemRaw @ "(skip)");
			continue;
		}

		ItemList.AddItem(ItemWeapDef);
		`Log_Debug("[" $ Line + 1 $ "]" @ "Loaded successfully:" @ ItemRaw);
	}

	if (ItemList.Length == default.Item.Length)
	{
		`Log_Info("Items to add list loaded successfully (" $ default.Item.Length @ "entries)");
	}
	else
	{
		`Log_Info("Items to add list: loaded" @ ItemList.Length @ "of" @ default.Item.Length @ "entries");
	}

	return ItemList;
}

defaultproperties
{

}
