class Unlocker extends Object
	abstract;

// TODO:
// replace shopContainer (KFGFxTraderContainer_Store)
// without replacing KFGFxMoviePlayer_Manager
// but how? 🤔

const Trader = class'Trader';

var private const Array<class<KFWeaponDefinition> > WeapDefDLCReplacements;

public static function bool IsValidTypeUnlockDLC(String UnlockType, E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	switch (Locs(UnlockType))
	{
		case "true":
		case "false":
		case "auto":
		case "replaceweapons":
		case "replacefilter":
			return true;
	}

	return false;
}

public static function bool UnlockDLC(
	KFGameInfo KFGI,
	KFGameReplicationInfo KFGRI,
	String UnlockType,
	out Array<class<KFWeaponDefinition> > RemoveItems,
	out Array<class<KFWeaponDefinition> > AddItems,
	E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	switch (Locs(UnlockType))
	{
		case "true":
		case "auto":
			return Auto(KFGI, KFGRI, RemoveItems, AddItems, LogLevel);

		case "replaceweapons":
			return ReplaceWeapons(KFGRI, RemoveItems, AddItems, LogLevel);

		case "replacefilter":
			return ReplaceFilter(KFGI, LogLevel);

		case "false":
		default:
			return false;
	}
}

private static function bool Auto(
	KFGameInfo KFGI,
	KFGameReplicationInfo KFGRI,
	out Array<class<KFWeaponDefinition> > RemoveItems,
	out Array<class<KFWeaponDefinition> > AddItems,
	E_LogLevel LogLevel)
{
	local bool CustomGFxManager;

	`Log_TraceStatic();

	if (KFGI == None) return false;

	if (KFGameInfo_VersusSurvival(KFGI) != None)
	{
		CustomGFxManager = (KFGI.KFGFxManagerClass != class'KFGameInfo_VersusSurvival'.default.KFGFxManagerClass);
	}
	else
	{
		CustomGFxManager = (KFGI.KFGFxManagerClass != class'KFGameInfo'.default.KFGFxManagerClass);
	}

	if (CustomGFxManager)
	{
		return ReplaceWeapons(KFGRI, RemoveItems, AddItems, LogLevel);
	}
	else
	{
		return ReplaceFilter(KFGI, LogLevel);
	}
}

private static function bool ReplaceWeapons(
	KFGameReplicationInfo KFGRI,
	out Array<class<KFWeaponDefinition> > RemoveItems,
	out Array<class<KFWeaponDefinition> > AddItems,
	E_LogLevel LogLevel)
{
	local Array<class<KFWeaponDefinition> > WeapDefsDLCs;
	local class<KFWeaponDefinition> WeapDefDLC;
	local class<KFWeaponDefinition> WeapDefReplacement;
	local bool Unlock, PartialUnlock;

	`Log_TraceStatic();

	Unlock = false;
	PartialUnlock = false;

	WeapDefsDLCs = Trader.static.GetTraderWeapDefsDLC(KFGRI, LogLevel);

	foreach WeapDefsDLCs(WeapDefDLC)
	{
		WeapDefReplacement = PickReplacementWeapDefDLC(WeapDefDLC, LogLevel);
		if (WeapDefReplacement != None)
		{
			Unlock = true;
			if (AddItems.Find(WeapDefReplacement) == INDEX_NONE)
			{
				AddItems.AddItem(WeapDefReplacement);
			}
			`Log_Debug(WeapDefDLC @ "replaced by" @ WeapDefReplacement);
		}
		else
		{
			PartialUnlock = true;
			`Log_Warn("Can't unlock item:" @ WeapDefDLC @ "SharedUnlockId:" @ WeapDefDLC.default.SharedUnlockId);
		}

		if (RemoveItems.Find(WeapDefDLC) == INDEX_NONE)
		{
			RemoveItems.AddItem(WeapDefDLC);
		}
	}

	if (PartialUnlock)
	{
		`Log_Warn("Some DLCs are not unlocked. Try to set 'UnlockDLC=ReplaceFilter' or ask the author to update the mod");
	}

	return Unlock;
}

private static function class<KFWeaponDefinition> PickReplacementWeapDefDLC(class<KFWeaponDefinition> WeapDefDLC, E_LogLevel LogLevel)
{
	local class<KFWeaponDefinition> WeapDef;

	`Log_TraceStatic();

	foreach default.WeapDefDLCReplacements(WeapDef)
	{
		if (ClassIsChildOf(WeapDef, WeapDefDLC))
		{
			return WeapDef;
		}
	}

	return None;
}

private static function bool ReplaceFilter(KFGameInfo KFGI, E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	if (KFGI == None) return false;

	if (KFGameInfo_VersusSurvival(KFGI) != None)
	{
		KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager_Versus';
	}
	else
	{
		KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager';
	}

	return true;
}

defaultproperties
{
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_AutoTurret')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_BladedPistol')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Blunderbuss')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ChainBat')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ChiappaRhino')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ChiappaRhinoDual')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_CompoundBow')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Doshinegun')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_DualBladed')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_FAMAS')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_G18')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_G36C')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_GravityImploder')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_HVStormCannon')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_IonThruster')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_MG3')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Mine_Reconstructor')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Minigun')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_MosinNagant')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ParasiteImplanter')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Pistol_DualG18')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Pistol_G18C')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Rifle_FrostShotgunAxe')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Scythe')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Shotgun_S12')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ShrinkRayGun')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ThermiteBore')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_ZedMKIII')
	WeapDefDLCReplacements.Add(class'CTI_WeapDef_Zweihander')
}
