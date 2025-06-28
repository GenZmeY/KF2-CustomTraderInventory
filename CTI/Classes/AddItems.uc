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
