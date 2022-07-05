class RemoveItems extends Object
	dependson(CTI)
	config(CTI);

var public  config bool bAll;
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
	default.bAll = false;
	default.Item.Length = 0;
	default.Item.AddItem("KFGame.KFWeapDef_9mmDual");
}

public static function Array<class<KFWeaponDefinition> > Load(E_LogLevel LogLevel)
{
	local Array<class<KFWeaponDefinition> > ItemList;
	local class<KFWeaponDefinition> ItemClass;
	local String ItemRaw;
	local int    Line;
	
	`Log_Info("Load items to remove:");
	if (default.bAll)
	{
		`Log_Info("Remove all default items");
	}
	else
	{
		foreach default.Item(ItemRaw, Line)
		{
			ItemClass = class<KFWeaponDefinition>(DynamicLoadObject(ItemRaw, class'Class'));
			if (ItemClass == None)
			{
				`Log_Warn("[" $ Line + 1 $ "]" @ "Can't load item class:" @ ItemRaw);
			}
			else
			{
				ItemList.AddItem(ItemClass);
				`Log_Debug("[" $ Line + 1 $ "]" @ "Loaded successfully:" @ ItemRaw);
			}
		}
		
		if (ItemList.Length == default.Item.Length)
		{
			`Log_Info("Items to remove list loaded successfully (" $ default.Item.Length @ "entries)");
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
