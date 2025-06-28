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

class CTI_GFxTraderContainer_Store extends KFGFxTraderContainer_Store;

function bool IsItemFiltered(STraderItem Item, optional bool bDebug)
{
	if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.ClassName))
		return true;
	if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.DualClassName))
		return true;
	if (!KFPC.GetPurchaseHelper().IsSellable(Item))
		return true;
	if (Item.WeaponDef.default.PlatformRestriction != PR_All && class'KFUnlockManager'.static.IsPlatformRestricted(Item.WeaponDef.default.PlatformRestriction))
		return true;

	if (Has9mmGun())
	{
		if ((Item.ClassName == 'KFWeap_HRG_93r' || Item.ClassName == 'KFWeap_HRG_93r_Dual'))
			return true;
	}
	else
	{
		if ((Item.ClassName == 'KFWeap_Pistol_9mm' || Item.ClassName == 'KFWeap_Pistol_Dual9mm'))
			return true;
	}

	return false;
}

defaultproperties
{

}
