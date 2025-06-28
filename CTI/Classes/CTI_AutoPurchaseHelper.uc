// This file is part of Custom Trader Inventory.
// Custom Trader Inventory - a mutator for Killing Floor 2.
//
// Copyright (C) 2016-2023 Tripwire Interactive LLC (code parts from KFAutoPurchaseHelper)
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

class CTI_AutoPurchaseHelper extends KFAutoPurchaseHelper;

var private CTI_GFxObject_TraderItems CTI_TraderItems;
var private CTI_InventoryManager CTI_IM;

private function CTI_GFxObject_TraderItems GetCTI_TraderItems()
{
	if (CTI_TraderItems == None)
	{
		if (TraderItems == None)
		{
			GetTraderItems();
		}

		if (TraderItems != None)
		{
			CTI_TraderItems = CTI_GFxObject_TraderItems(TraderItems);
		}
	}

	return CTI_TraderItems;
}

private function CTI_InventoryManager GetCTI_IM()
{
	if (CTI_IM != Pawn.InvManager)
	{
		`Log_Base("Update InvManager:" @ String(CTI_IM) @ "<-" @ String(Pawn.InvManager));
		CTI_IM = CTI_InventoryManager(Pawn.InvManager);
	}

	return CTI_IM;
}

public function Initialize(optional bool bInitializeOwned = true)
{
	Super.Initialize(bInitializeOwned);
	GetCTI_IM();
	GetCTI_TraderItems();
}

public function bool UpgradeWeapon(int OwnedItemIndex)
{
	local int ItemIndex;
	local STraderItem DefaultItemInfo;
	local SItemInformation ItemInfo;
	local int Test1, Test2;

	ItemInfo = OwnedItemList[OwnedItemIndex];
	DefaultItemInfo = ItemInfo.DefaultItem;

	if (ItemInfo.bIsSecondaryAmmo || !CanUpgrade(DefaultItemInfo, Test1, Test2, true))
	{
		return false;
	}

	if (GetCTI_IM() == None) return false;

	CTI_GetItemIndicesFromArche(ItemIndex, DefaultItemInfo.ClassName);
	CTI_IM.CTI_BuyUpgrade(ItemIndex, ItemInfo.ItemUpgradeLevel);
	OwnedItemList[OwnedItemIndex].SellPrice = GetAdjustedSellPriceFor(DefaultItemInfo);

	if (MyGfxManager != None && MyGfxManager.TraderMenu != None)
	{
		MyGfxManager.TraderMenu.OwnedItemList = OwnedItemList;
	}

	return true;
}

public function BoughtAmmo(float AmountPurchased, int Price, EItemType ItemType, optional name ClassName, optional bool bIsSecondaryAmmo)
{
	local int ItemIndex;
	AddDosh(-Price);

	if (ItemType == EIT_Weapon)
	{
		CTI_GetItemIndicesFromArche(ItemIndex, ClassName);
	}

	if (GetCTI_IM() == None) return;

	CTI_IM.CTI_BuyAmmo(AmountPurchased, ItemType, ItemIndex, bIsSecondaryAmmo);
}

private function float AmmoCostScale()
{
	local KFGameReplicationInfo KFGRI;
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	return KFGRI == None? 1.0f : KFGRI.GameAmmoCostScale;
}

public function int AddWeaponToOwnedItemList(STraderItem DefaultItem, optional bool bDoNotBuy, optional int OverrideItemUpgradeLevel = INDEX_NONE)
{
	local SItemInformation WeaponInfo;
	local int ItemIndex, AddedWeaponIndex, OwnedSingleIdx, SingleDualAmmoDiff;
	local bool bAddingDual;

	WeaponInfo.MagazineCapacity = DefaultItem.MagazineCapacity;
	CurrentPerk.ModifyMagSizeAndNumber(None, WeaponInfo.MagazineCapacity, DefaultItem.AssociatedPerkClasses,, DefaultItem.ClassName);

	WeaponInfo.MaxSpareAmmo = DefaultItem.MaxSpareAmmo;
	CurrentPerk.ModifyMaxSpareAmmoAmount(none, WeaponInfo.MaxSpareAmmo, DefaultItem);
	WeaponInfo.MaxSpareAmmo += WeaponInfo.MagazineCapacity;

	WeaponInfo.SpareAmmoCount = DefaultItem.InitialSpareMags * DefaultItem.MagazineCapacity;
	CurrentPerk.ModifySpareAmmoAmount(none, WeaponInfo.SpareAmmoCount, DefaultItem);
	WeaponInfo.SpareAmmoCount += WeaponInfo.MagazineCapacity;

	bAddingDual = DefaultItem.SingleClassName != '';
	if (bAddingDual)
	{
		for (OwnedSingleIdx = 0; OwnedSingleIdx < OwnedItemList.Length; ++OwnedSingleIdx)
		{
			if (OwnedItemList[OwnedSingleIdx].DefaultItem.ClassName != DefaultItem.SingleClassName) continue;

			SingleDualAmmoDiff = OwnedItemList[OwnedSingleIdx].SpareAmmoCount - WeaponInfo.SpareAmmoCount;
			SingleDualAmmoDiff = Max(0, SingleDualAmmoDiff);

			if (WeaponInfo.SpareAmmoCount > OwnedItemList[OwnedSingleIdx].SpareAmmoCount)
			{
				OwnedItemList[OwnedSingleIdx].SpareAmmoCount = WeaponInfo.SpareAmmoCount;
			}
			else
			{
				WeaponInfo.SpareAmmoCount = Min(OwnedItemList[OwnedSingleIdx].SpareAmmoCount, WeaponInfo.MaxSpareAmmo);
			}

			WeaponInfo.ItemUpgradeLevel = OwnedItemList[OwnedSingleIdx].ItemUpgradeLevel;
			break;
		}
	}

	CurrentPerk.MaximizeSpareAmmoAmount(DefaultItem.AssociatedPerkClasses, WeaponInfo.SpareAmmoCount, DefaultItem.MaxSpareAmmo + DefaultItem.MagazineCapacity);

	WeaponInfo.SecondaryAmmoCount = DefaultItem.InitialSecondaryAmmo;
	CurrentPerk.ModifyMagSizeAndNumber(None, WeaponInfo.MagazineCapacity, DefaultItem.AssociatedPerkClasses, true, DefaultItem.ClassName);
	CurrentPerk.ModifySpareAmmoAmount(None, WeaponInfo.SecondaryAmmoCount, DefaultItem, true);

	WeaponInfo.MaxSecondaryAmmo = DefaultItem.MaxSecondaryAmmo;
	CurrentPerk.ModifyMaxSpareAmmoAmount(None, WeaponInfo.MaxSecondaryAmmo, DefaultItem, true);

	WeaponInfo.AmmoPricePerMagazine = AmmoCostScale() * DefaultItem.WeaponDef.default.AmmoPricePerMag;
	WeaponInfo.SellPrice = GetAdjustedSellPriceFor(DefaultItem);

	WeaponInfo.DefaultItem = DefaultItem;

	if (OverrideItemUpgradeLevel > INDEX_NONE)
	{
		WeaponInfo.ItemUpgradeLevel = OverrideItemUpgradeLevel;
	}

	AddedWeaponIndex = AddItemByPriority(WeaponInfo);

	if (GetCTI_IM() == None) return AddedWeaponIndex;

	CTI_GetItemIndicesFromArche(ItemIndex, DefaultItem.ClassName);

	if (!bDoNotBuy)
	{
		CTI_IM.CTI_ServerBuyWeapon(ItemIndex, WeaponInfo.ItemUpgradeLevel);
	}
	else
	{
		CTI_IM.CTI_ServerAddTransactionItem(ItemIndex, WeaponInfo.ItemUpgradeLevel);
		AddBlocks(CTI_IM.GetWeaponBlocks(DefaultItem, WeaponInfo.ItemUpgradeLevel));
	}

	if (bAddingDual)
	{
		CTI_AddTransactionAmmo(ItemIndex, SingleDualAmmoDiff, false);
		RemoveWeaponFromOwnedItemList(, DefaultItem.SingleClassName, true);
	}

	return AddedWeaponIndex;
}

public function RemoveWeaponFromOwnedItemList(optional int OwnedListIdx = INDEX_NONE, optional name ClassName, optional bool bDoNotSell)
{
	local SItemInformation ItemInfo;
	local int ItemIndex;
	local int SingleOwnedIndex;

	if (OwnedListIdx == INDEX_NONE && ClassName != '')
	{
		for (OwnedListIdx = 0; OwnedListIdx < OwnedItemList.length; ++OwnedListIdx)
		{
			if (OwnedItemList[OwnedListIdx].DefaultItem.ClassName == ClassName) break;
		}
	}

	if (OwnedListIdx >= OwnedItemList.length) return;

	ItemInfo = OwnedItemList[OwnedListIdx];

	if (GetCTI_IM() == None) return;

	if (!bDoNotSell)
	{
		CTI_GetItemIndicesFromArche(ItemIndex, ItemInfo.DefaultItem.ClassName);
		CTI_IM.CTI_ServerSellWeapon(ItemIndex);
	}
	else
	{
		AddBlocks(-CTI_IM.GetDisplayedBlocksRequiredFor(ItemInfo.DefaultItem));
		CTI_GetItemIndicesFromArche(ItemIndex, ItemInfo.DefaultItem.ClassName);
		CTI_IM.CTI_ServerRemoveTransactionItem(ItemIndex);
	}

	if (OwnedItemList[OwnedListIdx].bIsSecondaryAmmo)
	{
		OwnedItemList.Remove(OwnedListIdx, 1);
		if (OwnedListIdx - 1 >= 0)
		{
			OwnedItemList.Remove(OwnedListIdx - 1, 1);
		}
	}
	else if (OwnedItemList[OwnedListIdx].DefaultItem.WeaponDef.static.UsesSecondaryAmmo())
	{
		if (OwnedListIdx + 1 < OwnedItemList.Length)
		{
			OwnedItemList.Remove(OwnedListIdx + 1, 1);
			OwnedItemList.Remove(OwnedListIdx, 1);
		}
	}
	else
	{
		OwnedItemList.Remove(OwnedListIdx, 1);
	}

	if (ItemInfo.DefaultItem.SingleClassName == 'KFWeap_Pistol_9mm' || ItemInfo.DefaultItem.SingleClassName == 'KFWeap_HRG_93R')
	{
		if (CTI_GetItemIndicesFromArche(ItemIndex, ItemInfo.DefaultItem.SingleClassName))
		{
			SingleOwnedIndex = AddWeaponToOwnedItemList(CTI_TraderItems.AllItems[ItemIndex], true, ItemInfo.ItemUpgradeLevel);

			CTI_AddTransactionAmmo(ItemIndex, ItemInfo.SpareAmmoCount - (ItemInfo.MaxSpareAmmo / 2.0) + ((ItemInfo.MaxSpareAmmo / 2.0) - OwnedItemList[SingleOwnedIndex].SpareAmmoCount), false);
			OwnedItemList[SingleOwnedIndex].SpareAmmoCount = ItemInfo.SpareAmmoCount;
		}
	}

	if (MyGfxManager != None && MyGfxManager.TraderMenu != None)
	{
		MyGfxManager.TraderMenu.OwnedItemList = OwnedItemList;
	}
}

public function SetWeaponInformation(KFWeapon KFW)
{
	local int i;

	if (GetCTI_TraderItems() == None)
	{
		Super.SetWeaponInformation(KFW);
		return;
	}

	for (i = 0; i < CTI_TraderItems.AllItems.Length; i++)
	{
		if (KFW.Class.name == CTI_TraderItems.AllItems[i].ClassName)
		{
			SetWeaponInfo(KFW, CTI_TraderItems.AllItems[i]);
			return;
		}
	}
}

// native private final function AddTransactionAmmo( byte ItemIndex, int Amount, bool bSecondaryAmmo );
private function CTI_AddTransactionAmmo(int ItemIndex, int Amount, bool bSecondaryAmmo); // TODO: impl

private function bool CTI_GetItemIndicesFromArche(out int ItemIndex, name WeaponClassName)
{
	local int Index;

	if (GetCTI_TraderItems() == None) return false;

	Index = CTI_TraderItems.AllItems.Find('ClassName', WeaponClassName);

	if (Index == INDEX_NONE) return false;

	ItemIndex = Index;

	return true;
}

defaultproperties
{

}
