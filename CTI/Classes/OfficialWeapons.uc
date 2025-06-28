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

class OfficialWeapons extends Object
	config(CTI);

const Trader = class'Trader';
const DefaultComment = "Auto-generated list of official weapons for your convenience, copy-paste ready";

var private config String Comment;
var private config Array<String> Item;

private delegate int ByName(String A, String B)
{
	return A > B ? -1 : 0;
}

public static function Update(bool Enabled)
{
	local Array<class<KFWeaponDefinition> > KFWeapDefs;
	local class<KFWeaponDefinition> KFWeapDef;

	if (!Enabled) return;

	KFWeapDefs = Trader.static.GetTraderWeapDefs();

	if (default.Item.Length != KFWeapDefs.Length || default.Comment != DefaultComment)
	{
		default.Comment = DefaultComment;
		default.Item.Length = 0;

		foreach KFWeapDefs(KFWeapDef)
		{
			default.Item.AddItem(KFWeapDef.GetPackageName() $ "." $ KFWeapDef);
		}

		default.Item.Sort(ByName);

		StaticSaveConfig();
	}
}

defaultproperties
{

}
