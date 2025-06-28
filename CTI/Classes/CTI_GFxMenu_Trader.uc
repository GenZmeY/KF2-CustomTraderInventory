// This file is part of Custom Trader Inventory.
// Custom Trader Inventory - a mutator for Killing Floor 2.
//
// Copyright (C) 2015-2024 Tripwire Interactive LLC (code parts from KFGFxMenu_Trader)
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

class CTI_GFxMenu_Trader extends KFGFxMenu_Trader
	dependsOn(CTI_GFxTraderContainer_Store);

var private int SelectedItemIndexInt;

private function UpdateByteSelectedIndex()
{
	SelectedItemIndex = Clamp(SelectedItemIndexInt, 0, 255);
}

public function SetTraderItemDetails(int ItemIndex)
{
	local STraderItem SelectedItem;
	local bool bCanAfford, bCanBuyItem, bCanCarry;
	SelectedList = TL_Shop;

	if (ItemDetails == None || ShopContainer == None) return;

	if (MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.length >= 0 && ItemIndex < MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.length)
	{
		SelectedItemIndexInt = ItemIndex;
		SelectedItem = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[ItemIndex];

		bCanAfford = MyKFPC.GetPurchaseHelper().GetCanAfford(MyKFPC.GetPurchaseHelper().GetAdjustedBuyPriceFor(SelectedItem));
		bCanCarry = MyKFPC.GetPurchaseHelper().CanCarry(SelectedItem);

		bCanBuyItem = bCanAfford && bCanCarry;

		PurchaseError(!bCanAfford, !bCanCarry);

		ItemDetails.SetShopItemDetails(SelectedItem, MyKFPC.GetPurchaseHelper().GetAdjustedBuyPriceFor(SelectedItem), bCanCarry, bCanBuyItem);
		bCanBuyOrSellItem = bCanBuyItem;
	}
	else
	{
		ItemDetails.SetVisible(false);
	}

	UpdateByteSelectedIndex();
}

public function SetPlayerItemDetails(int ItemIndex)
{
	local STraderItem SelectedItem;

	SelectedList = TL_Player;
	if (ItemDetails == None || ItemIndex >= OwnedItemList.length) return;

	bGenericItemSelected = false;
	SelectedItemIndexInt = ItemIndex;
	SelectedItem = OwnedItemList[ItemIndex].DefaultItem;
	ItemDetails.SetPlayerItemDetails(SelectedItem, OwnedItemList[ItemIndex].SellPrice, OwnedItemList[ItemIndex].ItemUpgradeLevel);
	bCanBuyOrSellItem = MyKFPC.GetPurchaseHelper().IsSellable(SelectedItem);
	PurchaseError(false, false);

	UpdateByteSelectedIndex();
}

public function SetNewSelectedIndex(int ListLength)
{
	if (SelectedItemIndexInt >= ListLength)
	{
		if (SelectedItemIndexInt != 0)
		{
			SelectedItemIndexInt--;
		}
	}

	UpdateByteSelectedIndex();
}

public function RefreshItemComponents(optional bool bInitOwnedItems = false)
{
	if (PlayerInventoryContainer == None || PlayerInfoContainer == None) return;

	if (bInitOwnedItems)
	{
		MyKFPC.GetPurchaseHelper().InitializeOwnedItemList();
	}
	OwnedItemList = MyKFPC.GetPurchaseHelper().OwnedItemList;
	PlayerInventoryContainer.RefreshPlayerInventory();
	RefreshShopItemList(CurrentTab, CurrentFilterIndex);
	GameInfoContainer.UpdateGameInfo();
	GameInfoContainer.SetDosh(MyKFPC.GetPurchaseHelper().TotalDosh);
	GameInfoContainer.SetCurrentWeight(MyKFPC.GetPurchaseHelper().TotalBlocks, MyKFPC.GetPurchaseHelper().MaxBlocks);

	if (SelectedList == TL_Shop)
	{
		SetTraderItemDetails(SelectedItemIndexInt);
	}
	else if (bGenericItemSelected)
	{
		SetGenericItemDetails(LastDefaultItemInfo, LastItemInfo);
	}
	else
	{
		SetPlayerItemDetails(SelectedItemIndexInt);
	}
}

public function RefreshShopItemList(TabIndices TabIndex, byte FilterIndex)
{
	if (ShopContainer == None || FilterContainer == None) return;

	switch (TabIndex)
	{
		case (TI_Perks):
			ShopContainer.RefreshWeaponListByPerk(FilterIndex, MyKFPC.GetPurchaseHelper().TraderItems.SaleItems);
			FilterContainer.SetPerkFilterData(FilterIndex);
		break;
		case (TI_Type):
			ShopContainer.RefreshItemsByType(FilterIndex, MyKFPC.GetPurchaseHelper().TraderItems.SaleItems);
			FilterContainer.SetTypeFilterData(FilterIndex);
		break;
		case (TI_Favorites):
			ShopContainer.RefreshFavoriteItems(MyKFPC.GetPurchaseHelper().TraderItems.SaleItems);
			FilterContainer.ClearFilters();
		break;
		case (TI_All):
			ShopContainer.RefreshAllItems(MyKFPC.GetPurchaseHelper().TraderItems.SaleItems);
			FilterContainer.ClearFilters();
		break;
	}

	FilterContainer.SetInt("selectedTab", TabIndex);
	FilterContainer.SetInt("selectedFilter", FilterIndex);

	if (SelectedList == TL_Shop)
	{
		if (SelectedItemIndexInt >= MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.length)
		{
			SelectedItemIndexInt = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.length - 1;
		}

		SetTraderItemDetails(SelectedItemIndexInt);
		ShopContainer.SetSelectedIndex(SelectedItemIndexInt);
	}
}

public function Callback_BuyOrSellItem()
{
	local STraderItem ShopItem;
	local SItemInformation ItemInfo;

	if (bCanBuyOrSellItem)
	{
		if (SelectedList == TL_Shop)
		{
			ShopItem = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[SelectedItemIndexInt];

			MyKFPC.GetPurchaseHelper().PurchaseWeapon(ShopItem);
			SetNewSelectedIndex(MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.length);
			SetTraderItemDetails(SelectedItemIndexInt);
			ShopContainer.ActionScriptVoid("itemBought");
		}
		else
		{
			ItemInfo = OwnedItemList[SelectedItemIndexInt];
			MyKFPC.GetPurchaseHelper().SellWeapon(ItemInfo, SelectedItemIndexInt);

			SetNewSelectedIndex(OwnedItemList.length);
			SetPlayerItemDetails(SelectedItemIndexInt);
			PlayerInventoryContainer.ActionScriptVoid("itemSold");
		}
	}
	else if (SelectedList == TL_Shop)
	{
		ShopItem = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[SelectedItemIndexInt];

		MyKFPC.PlayTraderSelectItemDialog(!MyKFPC.GetPurchaseHelper().GetCanAfford(MyKFPC.GetPurchaseHelper().GetAdjustedBuyPriceFor(ShopItem)), !MyKFPC.GetPurchaseHelper().CanCarry(ShopItem));
	}
	RefreshItemComponents();
}

public function Callback_FavoriteItem()
{
	if (SelectedList == TL_Shop)
	{
		ToggleFavorite(MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[SelectedItemIndexInt].ClassName);
		if (CurrentTab == TI_Favorites)
		{
			SetNewSelectedIndex(MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.length);
		}
		SetTraderItemDetails(SelectedItemIndexInt);
	}
	else
	{
		ToggleFavorite(OwnedItemList[SelectedItemIndexInt].DefaultItem.ClassName);
		SetPlayerItemDetails(SelectedItemIndexInt);
	}
	RefreshItemComponents();
}

public function Callback_UpgradeItem()
{
	local SItemInformation ItemInfo;
	local KFAutoPurchaseHelper PurchaseHelper;

	if (SelectedList != TL_Player) return;

	PurchaseHelper = MyKFPC.GetPurchaseHelper();
	if (PurchaseHelper.UpgradeWeapon(SelectedItemIndexInt))
	{
		ItemInfo = PurchaseHelper.OwnedItemList[SelectedItemIndexInt];
		PurchaseHelper.OwnedItemList[SelectedItemIndexInt].ItemUpgradeLevel++;
		PurchaseHelper.OwnedItemList[SelectedItemIndexInt].SellPrice =
			PurchaseHelper.GetAdjustedSellPriceFor(ItemInfo.DefaultItem);
		RefreshItemComponents();
		ShopContainer.ActionScriptVoid("itemBought");
		class'KFMusicStingerHelper'.static.PlayWeaponUpgradeStinger(MyKFPC);
	}
}

defaultproperties
{

}
