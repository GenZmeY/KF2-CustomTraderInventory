class RemoveItems extends Object
	dependson(CTI)
	config(CTI);

var public  config bool bAll;
var public  config bool bHRG;
var public  config bool bDLC;
var private config Array<String> Item;

public static function InitConfig(int Version, int LatestVersion)
{
	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault();
			
		case 2:
			default.bHRG = false;
			default.bDLC = false;
			
		default: break;
	}
	
	if (LatestVersion != Version)
	{
		StaticSaveConfig();
	}
}

private static function ApplyDefault()
{
	default.bAll = false;
	default.bHRG = false;
	default.bDLC = false;
	default.Item.Length = 0;
	default.Item.AddItem("KFGame.KFWeapDef_9mmDual");
}

public static function Array<class<KFWeaponDefinition> > Load(E_LogLevel LogLevel)
{
	local Array<class<KFWeaponDefinition> > ItemList;
	local class<KFWeaponDefinition> ItemWeapDef;
	local class<KFWeapon> ItemWeapon;
	local String ItemRaw;
	local int    Line;
	
	`Log_Info("Load items to remove:");
	if (default.bAll)
	{
		`Log_Info("Remove all default items");
	}
	else
	{
		if (default.bHRG)
		{
			`Log_Info("Remove all HRG items");
		}
		if (default.bDLC)
		{
			`Log_Info("Remove all DLC items");
		}
		
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
			`Log_Info("Items to remove list loaded successfully (" $ ItemList.Length @ "entries)");
		}
		else
		{
			`Log_Info("Items to remove list: loaded" @ ItemList.Length @ "of" @ default.Item.Length @ "entries");
		}
	}
	
	return ItemList;
}

defaultproperties
{

}
