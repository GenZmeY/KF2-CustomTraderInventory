// This file is part of Custom Trader Inventory.
// Custom Trader Inventory - a mutator for Killing Floor 2.
//
// Copyright (C) 2022-2024 GenZmeY (mailto: genzmey@gmail.com)
//
// Custom Trader Inventory is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Custom Trader Inventory is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with Custom Trader Inventory. If not, see <https://www.gnu.org/licenses/>.

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
	out Array<class<KFWeaponDefinition> > WeapDefs,
	out BoolWrapper DLCSkinUpdateRequired,
	E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	switch (Locs(UnlockType))
	{
		case "true":
		case "auto":
			return Auto(KFGI, KFGRI, WeapDefs, DLCSkinUpdateRequired, LogLevel);

		case "replaceweapons":
			return ReplaceWeapons(KFGRI, WeapDefs, DLCSkinUpdateRequired, LogLevel);

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
	out Array<class<KFWeaponDefinition> > WeapDefs,
	out BoolWrapper DLCSkinUpdateRequired,
	E_LogLevel LogLevel)
{
	`Log_TraceStatic();

	if (KFGI == None) return false;

	if (CustomGFxManager(KFGI))
	{
		return ReplaceWeapons(KFGRI, WeapDefs, DLCSkinUpdateRequired, LogLevel);
	}
	else
	{
		DLCSkinUpdateRequired.Value = false;
		return ReplaceFilter(KFGI, LogLevel);
	}
}

public static function bool CustomGFxManager(KFGameInfo KFGI)
{
	if (KFGameInfo_VersusSurvival(KFGI) != None)
	{
		return (KFGI.KFGFxManagerClass != class'KFGameInfo_VersusSurvival'.default.KFGFxManagerClass);
	}
	else
	{
		return (KFGI.KFGFxManagerClass != class'KFGameInfo'.default.KFGFxManagerClass);
	}
}

private static function bool ReplaceWeapons(
	KFGameReplicationInfo KFGRI,
	out Array<class<KFWeaponDefinition> > WeapDefs,
	out BoolWrapper DLCSkinUpdateRequired,
	E_LogLevel LogLevel)
{
	local class<KFWeaponDefinition> WeapDef;
	local class<KFWeaponDefinition> WeapDefReplacement;
	local bool Unlock, PartialUnlock;
	local int Index;

	`Log_TraceStatic();

	`Log_Debug("Unlock by replace weapons");

	Unlock = false;
	PartialUnlock = false;
	DLCSkinUpdateRequired.Value = false;

	for (Index = 0; Index < WeapDefs.Length; Index++)
	{
		WeapDef = WeapDefs[Index];

		if (WeapDef.default.SharedUnlockId == SCU_None) continue;

		WeapDefReplacement = PickReplacementWeapDefDLC(WeapDef, LogLevel);
		if (WeapDefReplacement != None)
		{
			Unlock = true;
			DLCSkinUpdateRequired.Value = true;
			if (WeapDefs.Find(WeapDefReplacement) == INDEX_NONE)
			{
				WeapDefs[Index] = WeapDefReplacement;
				`Log_Debug(WeapDef @ "replaced by" @ WeapDefReplacement);
			}
			else
			{
				WeapDefs.Remove(Index--, 1);
				`Log_Debug("Skip already unlocked weapon:" @ WeapDef);
			}
		}
		else
		{
			PartialUnlock = true;
			`Log_Warn("Can't unlock item:" @ WeapDef @ "SharedUnlockId:" @ WeapDef.default.SharedUnlockId);
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

	if (CustomGFxManager(KFGI))
	{
		`Log_Warn("Custom KFGFxMoviePlayer_Manager detected:" @ String(KFGI.KFGFxManagerClass) $ ". There may be compatibility issues.");
	}

	if (KFGameInfo_VersusSurvival(KFGI) != None)
	{
		KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager_Versus_DLC';
	}
	else
	{
		KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager_DLC';
	}

	return true;
}

defaultproperties
{

}
