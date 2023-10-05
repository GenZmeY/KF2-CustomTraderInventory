class Unlocker extends Object
	dependson(WeaponReplacements)
	abstract;

// TODO:
// replace shopContainer (KFGFxTraderContainer_Store)
// without replacing KFGFxMoviePlayer_Manager
// but how? 🤔

const Trader       = class'Trader';
const Replacements = class'WeaponReplacements';

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
	out BoolWrapper DLCSkinUpdateRequired,
	E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	switch (Locs(UnlockType))
	{
		case "true":
		case "auto":
			return Auto(KFGI, KFGRI, RemoveItems, AddItems, DLCSkinUpdateRequired, LogLevel);

		case "replaceweapons":
			DLCSkinUpdateRequired.Value = true;
			return ReplaceWeapons(KFGRI, RemoveItems, AddItems, LogLevel);

		case "replacefilter":
			DLCSkinUpdateRequired.Value = false;
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
	out BoolWrapper DLCSkinUpdateRequired,
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
		DLCSkinUpdateRequired.Value = true;
		return ReplaceWeapons(KFGRI, RemoveItems, AddItems, LogLevel);
	}
	else
	{
		DLCSkinUpdateRequired.Value = false;
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

	`Log_Debug("Unlock by replace weapons");

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
	local SWeapReplace WeapReplace;

	`Log_TraceStatic();

	foreach Replacements.default.DLC(WeapReplace)
	{
		if (ClassIsChildOf(WeapReplace.WeapDef, WeapDefDLC))
		{
			return WeapReplace.WeapDef;
		}
	}

	return None;
}

private static function bool ReplaceFilter(KFGameInfo KFGI, E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	`Log_Debug("Unlock by replace filter");

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

}
