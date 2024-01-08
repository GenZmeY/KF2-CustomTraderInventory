class CTI_InventoryManager extends KFInventoryManager;

// simulated function final BuyAmmo( float AmountPurchased, EItemType ItemType, optional byte ItemIndex, optional bool bSecondaryAmmo )
public simulated function CTI_BuyAmmo(float AmountPurchased, EItemType ItemType, optional int ItemIndex, optional bool bSecondaryAmmo)
{
	local STraderItem WeaponItem;
	local KFWeapon KFW;
	local int MagAmmoCount;

	switch (ItemType)
	{
		case EIT_Weapon:
			MagAmmoCount = INDEX_NONE;
			if (CTI_GetTraderItemFromWeaponLists(WeaponItem, ItemIndex) && GetWeaponFromClass(KFW, WeaponItem.ClassName))
			{
				MagAmmoCount = bSecondaryAmmo ? KFW.AmmoCount[1] : KFW.AmmoCount[0];
			}
			CTI_ServerBuyAmmo(int(AmountPurchased), MagAmmoCount, ItemIndex, bSecondaryAmmo);
		break;

		case EIT_Armor:   CTI_ServerBuyArmor(AmountPurchased);        break;
		case EIT_Grenade: CTI_ServerBuyGrenade(int(AmountPurchased)); break;
	}
}

// reliable server final private function ServerBuyAmmo(int AmountPurchased, byte ClientAmmoCount, byte ItemIndex, bool bSecondaryAmmo)
private reliable server function CTI_ServerBuyAmmo(int AmountPurchased, int ClientAmmoCount, int ItemIndex, bool bSecondaryAmmo)
{
	local STraderItem WeaponItem;
	local KFWeapon KFW;
	local int ClientMaxMagCapacity;

	if (Role != ROLE_Authority || !bServerTraderMenuOpen)              return;
	if (!CTI_GetTraderItemFromWeaponLists(WeaponItem, ItemIndex))      return;
	if (!CTI_ProcessAmmoDosh(WeaponItem, AmountPurchased, bSecondaryAmmo)) return;

	if (!GetWeaponFromClass(KFW, WeaponItem.ClassName))
	{
		CTI_ServerAddTransactionAmmo(AmountPurchased, ItemIndex, bSecondaryAmmo);
		return;
	}

	if (bSecondaryAmmo)
	{
		KFW.AddSecondaryAmmo(AmountPurchased);
	}
	else
	{
		if (ClientAmmoCount != INDEX_NONE)
		{
			ClientMaxMagCapacity = KFW.default.MagazineCapacity[0];
			if (KFW.GetPerk() != None)
			{
				KFW.GetPerk().ModifyMagSizeAndNumber(KFW, ClientMaxMagCapacity);
			}
			KFW.AmmoCount[0] = Clamp(ClientAmmoCount, 0, ClientMaxMagCapacity);
		}

		KFW.AddAmmo(AmountPurchased);
	}
}

// reliable server final private event ServerAddTransactionAmmo( int AmountAdded, byte ItemIndex, bool bSecondaryAmmo )
private reliable server event CTI_ServerAddTransactionAmmo(int AmountAdded, int ItemIndex, bool bSecondaryAmmo)
{
	local STraderItem WeaponItem;
	local int TransactionIndex;

	if (!bServerTraderMenuOpen) return;
	if (!CTI_GetTraderItemFromWeaponLists(WeaponItem, ItemIndex)) return;

	TransactionIndex = GetTransactionItemIndex(WeaponItem.ClassName);
	if (TransactionIndex == INDEX_NONE) return;

	TransactionItems[TransactionIndex].AddedAmmo[byte(bSecondaryAmmo)] += AmountAdded;
}

// simulated function final BuyUpgrade(byte ItemIndex, int CurrentUpgradeLevel)
public simulated function CTI_BuyUpgrade(int ItemIndex, int CurrentUpgradeLevel)
{
	local STraderItem WeaponItem;
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(Instigator.Owner);

	if (!CTI_GetTraderItemFromWeaponLists(WeaponItem, ItemIndex)) return;

	KFPC.GetPurchaseHelper().AddDosh(-WeaponItem.WeaponDef.static.GetUpgradePrice(CurrentUpgradeLevel)); //client tracking
	KFPC.GetPurchaseHelper().AddBlocks(-GetDisplayedBlocksRequiredFor(WeaponItem));//remove the old weight
	KFPC.GetPurchaseHelper().AddBlocks(GetDisplayedBlocksRequiredFor(WeaponItem, CurrentUpgradeLevel + 1)); //add the new
	CTI_ServerBuyUpgrade(ItemIndex, CurrentUpgradeLevel);
}

// reliable server final private function ServerBuyUpgrade(byte ItemIndex, int CurrentUpgradeLevel)
private reliable server function CTI_ServerBuyUpgrade(int ItemIndex, int CurrentUpgradeLevel)
{
	local STraderItem WeaponItem;
	local KFWeapon KFW;
	local int NewUpgradeLevel;

	if (Role != ROLE_Authority || !bServerTraderMenuOpen)         return;
	if (!CTI_GetTraderItemFromWeaponLists(WeaponItem, ItemIndex)) return;
	if (!CTI_ProcessUpgradeDosh(WeaponItem, CurrentUpgradeLevel)) return;

	NewUpgradeLevel = CurrentUpgradeLevel + 1;

	if (GetWeaponFromClass(KFW, WeaponItem.ClassName))
	{
		if (KFW == None) return;

		KFW.SetWeaponUpgradeLevel(NewUpgradeLevel);
		if (CurrentUpgradeLevel > 0)
		{
			AddCurrentCarryBlocks(-KFW.GetUpgradeStatAdd(EWUS_Weight, CurrentUpgradeLevel));
		}

		AddCurrentCarryBlocks(KFW.GetUpgradeStatAdd(EWUS_Weight, NewUpgradeLevel));
	}
	else
	{
		CTI_ServerAddTransactionUpgrade(ItemIndex, NewUpgradeLevel);
	}

}

// reliable server final function ServerBuyWeapon( byte ItemIndex, optional byte WeaponUpgrade )
public reliable server function CTI_ServerBuyWeapon(int ItemIndex, optional int WeaponUpgrade )
{
	local STraderItem PurchasedItem;
	local int BlocksRequired;

	if (Role != ROLE_Authority || !bServerTraderMenuOpen)            return;
	if (!CTI_GetTraderItemFromWeaponLists(PurchasedItem, ItemIndex)) return;

	BlocksRequired = GetWeaponBlocks(PurchasedItem, WeaponUpgrade);

	if (CurrentCarryBlocks > CurrentCarryBlocks + BlocksRequired) return;
	if (!CTI_ProcessWeaponDosh(PurchasedItem))                        return;

	CTI_AddTransactionItem(PurchasedItem, WeaponUpgrade);
}

// final function AddTransactionItem( const out STraderItem ItemToAdd, optional byte WeaponUpgrade )
public function CTI_AddTransactionItem(const out STraderItem ItemToAdd, optional int WeaponUpgrade)
{
	local TransactionItem NewTransactionItem;

	if (Role < ROLE_Authority || !bServerTraderMenuOpen) return;

	NewTransactionItem.ClassName = ItemToAdd.ClassName;
	NewTransactionItem.DLOString = ItemToAdd.WeaponDef.default.WeaponClassPath;
	NewTransactionItem.AddedAmmo[0] = 0;
	NewTransactionItem.AddedAmmo[1] = 0;
	NewTransactionItem.WeaponUpgradeLevel = WeaponUpgrade;

	TransactionItems.AddItem(NewTransactionItem);

	AddCurrentCarryBlocks(GetWeaponBlocks(ItemToAdd, WeaponUpgrade));
}

// reliable server final function ServerAddTransactionItem( byte ItemIndex, optional byte WeaponUpgrade)
public reliable server function CTI_ServerAddTransactionItem(int ItemIndex, optional int WeaponUpgrade)
{
	local STraderItem PurchasedItem;

	if (Role != ROLE_Authority || !bServerTraderMenuOpen) return;

	if (CTI_GetTraderItemFromWeaponLists(PurchasedItem, ItemIndex))
	{
		CTI_AddTransactionItem(PurchasedItem, WeaponUpgrade);
	}
}

// final function RemoveTransactionItem( const out STraderItem ItemToRemove )
final function CTI_RemoveTransactionItem(const out STraderItem ItemToRemove)
{
	local int Index;

	if (Role < ROLE_Authority || !bServerTraderMenuOpen) return;

	Index = GetTransactionItemIndex( ItemToRemove.ClassName );

	if (Index == INDEX_NONE) return;

	AddCurrentCarryBlocks(-GetDisplayedBlocksRequiredFor(ItemToRemove, TransactionItems[Index].WeaponUpgradeLevel));
	TransactionItems.Remove(Index, 1);
}

// reliable server final function ServerRemoveTransactionItem( int ItemIndex )
public reliable server final function CTI_ServerRemoveTransactionItem(int ItemIndex)
{
	local STraderItem ItemToRemove;
	local KFWeapon InvWeap;

	if (!bServerTraderMenuOpen) return;
	if (!CTI_GetTraderItemFromWeaponLists(ItemToRemove, ItemIndex)) return;

	CTI_RemoveTransactionItem(ItemToRemove);

	if (!GetWeaponFromClass(InvWeap, ItemToRemove.ClassName)) return;

	RemoveFromInventory(InvWeap);
}

// reliable server final function ServerSellWeapon( byte ItemIndex )
public reliable server function CTI_ServerSellWeapon(int ItemIndex)
{
	local STraderItem SoldItem;
	local int SellPrice, TransactionIndex;
	local KFWeapon KFW;
	local KFPlayerReplicationInfo KFPRI;

	if (Role != ROLE_Authority || !bServerTraderMenuOpen) return;

	KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

	if (KFPRI == None) return;

	if (!CTI_GetTraderItemFromWeaponLists(SoldItem, ItemIndex)) return;

	if (GetWeaponFromClass(KFW, SoldItem.ClassName))
	{
		SellPrice = GetAdjustedSellPriceFor(SoldItem);
		KFPRI.AddDosh(SellPrice);
		ServerRemoveFromInventory(KFW);
		KFW.Destroy();
	}
	else
	{
		TransactionIndex = GetTransactionItemIndex(SoldItem.ClassName);

		if (TransactionIndex == INDEX_NONE) return;

		SellPrice = GetAdjustedSellPriceFor(SoldItem);
		KFPRI.AddDosh(SellPrice);
		CTI_RemoveTransactionItem(SoldItem);
	}
}

// private final simulated function bool GetTraderItemFromWeaponLists(out STraderItem TraderItem, byte ItemIndex )
private simulated function bool CTI_GetTraderItemFromWeaponLists(out STraderItem TraderItem, int ItemIndex)
{
	local CTI_GFxObject_TraderItems TraderItems;

	if (WorldInfo.GRI == None) return false;

	TraderItems = CTI_GFxObject_TraderItems(KFGameReplicationInfo(WorldInfo.GRI).TraderItems);

	if (TraderItems == None) return false;

	if (ItemIndex < TraderItems.AllItems.Length)
	{
		TraderItem = TraderItems.AllItems[ItemIndex];
		return true;
	}

	return false;
}

// private final function bool ProcessWeaponDosh(out STraderItem PurchasedItem)
private function bool CTI_ProcessWeaponDosh(out STraderItem PurchasedItem)
{
	local int BuyPrice;
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
	if (KFPRI == None) return false;

	BuyPrice = GetAdjustedBuyPriceFor(PurchasedItem);

	if (KFPRI.Score - BuyPrice >= 0)
	{
		KFPRI.AddDosh(-BuyPrice);
		return true;
	}

	return false;
}

private function float AmmoCostScale()
{
	local KFGameReplicationInfo KFGRI;
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	return KFGRI == None ? 1.0f : KFGRI.GameAmmoCostScale;
}

// private final function bool ProcessAmmoDosh(out STraderItem PurchasedItem, int AdditionalAmmo, optional bool bSecondaryAmmo)
private function bool CTI_ProcessAmmoDosh(out STraderItem PurchasedItem, int AdditionalAmmo, optional bool bSecondaryAmmo)
{
	local int BuyPrice;
	local float PricePerMag, MagSize;
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
	if (KFPRI == None) return false;

	if (bSecondaryAmmo)
	{
		PricePerMag = AmmoCostScale() * PurchasedItem.WeaponDef.default.SecondaryAmmoMagPrice;
		MagSize = PurchasedItem.WeaponDef.default.SecondaryAmmoMagSize;
		BuyPrice = FCeil((PricePerMag / MagSize) * float(AdditionalAmmo));
	}
	else
	{
		PricePerMag = AmmoCostScale() * PurchasedItem.WeaponDef.default.AmmoPricePerMag;
		MagSize = PurchasedItem.MagazineCapacity;
		BuyPrice = FCeil((PricePerMag / MagSize) * float(AdditionalAmmo));
	}

	if (KFPRI.Score - BuyPrice >= 0)
	{
		KFPRI.AddDosh(-BuyPrice);
		return true;
	}

	return false;
}

// private final function bool ProcessUpgradeDosh(const out STraderItem PurchasedItem, int NewUpgradeLevel)
private function bool CTI_ProcessUpgradeDosh(const out STraderItem PurchasedItem, int NewUpgradeLevel)
{
	local int BuyPrice;
	local KFPlayerController KFPC;
	local KFPlayerReplicationInfo KFPRI;

	KFPC = KFPlayerController(Instigator.Owner);
	KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

	if (KFPC == None || KFPRI == none) return false;

	BuyPrice = PurchasedItem.WeaponDef.static.GetUpgradePrice(NewUpgradeLevel);
	if (BuyPrice <= KFPRI.Score)
	{
		KFPRI.AddDosh(-BuyPrice);
		return true;
	}

	return false;
}

// private final function bool ProcessGrenadeDosh(int AmountPurchased)
private function bool CTI_ProcessGrenadeDosh(int AmountPurchased)
{
	local int BuyPrice;
	local KFGFxObject_TraderItems TraderItems;
	local KFPlayerController KFPC;
	local KFPlayerReplicationInfo KFPRI;

	KFPC = KFPlayerController(Instigator.Owner);
	KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
	if (KFPC == None || KFPRI == None) return false;

	TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;
	BuyPrice = TraderItems.GrenadePrice * AmountPurchased;
	if (BuyPrice <= KFPRI.Score)
	{
		KFPRI.AddDosh(-BuyPrice);
		return true;
	}

	return false;
}

// reliable server final private function ServerBuyArmor( float PercentPurchased )
private reliable server function CTI_ServerBuyArmor(float PercentPurchased)
{
	local KFPawn_Human KFP;
	local int AmountPurchased;
	local float MaxArmor;

	KFP = KFPawn_Human(Instigator);
	if (Role != ROLE_Authority || KFP == none || !bServerTraderMenuOpen) return;
	if (!CTI_ProcessArmorDosh(PercentPurchased)) return;

	MaxArmor = KFP.GetMaxArmor();
	AmountPurchased = FCeil(MaxArmor * (PercentPurchased / 100.0));

	KFP.AddArmor(AmountPurchased);
}

// private final function bool ProcessArmorDosh(float PercentPurchased)
private function bool CTI_ProcessArmorDosh(float PercentPurchased)
{
	local int BuyPrice;
	local KFGFxObject_TraderItems TraderItems;
	local KFPlayerController KFPC;
	local KFPerk CurrentPerk;
	local int ArmorPricePerPercent;
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
	if (KFPRI == None) return false;

	TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;
	ArmorPricePerPercent = TraderItems.ArmorPrice;

	KFPC = KFPlayerController(Instigator.Owner);
	if (KFPC != None)
	{
		CurrentPerk = KFPC.GetPerk();
		if (CurrentPerk != None)
		{
			ArmorPricePerPercent *= CurrentPerk.GetArmorDiscountMod();
		}
	}

	BuyPrice = FCeil(ArmorPricePerPercent * PercentPurchased);
	if (BuyPrice <= KFPRI.Score)
	{
		KFPRI.AddDosh(-BuyPrice);
		return true;
	}

	return false;
}

// reliable server final private event ServerAddTransactionUpgrade(int ItemIndex, int NewUpgradeLevel)
private reliable server event CTI_ServerAddTransactionUpgrade(int ItemIndex, int NewUpgradeLevel)
{
	if (bServerTraderMenuOpen)
	{
		CTI_AddTransactionUpgrade(ItemIndex, NewUpgradeLevel);
	}
}

// final function AddTransactionUpgrade(int ItemIndex, int NewUpgradeLevel)
private function CTI_AddTransactionUpgrade(int ItemIndex, int NewUpgradeLevel)
{
	local STraderItem WeaponItem;
	local int TransactionIndex;

	if (Role < ROLE_Authority || !bServerTraderMenuOpen) return;

	if (CTI_GetTraderItemFromWeaponLists(WeaponItem, ItemIndex))
	{
		TransactionIndex = GetTransactionItemIndex(WeaponItem.ClassName);
		if (TransactionIndex == INDEX_NONE) return;

		TransactionItems[TransactionIndex].WeaponUpgradeLevel = NewUpgradeLevel;
		TransactionItems[TransactionIndex].AddedWeight = WeaponItem.WeaponUpgradeWeight[NewUpgradeLevel];
		if (NewUpgradeLevel > 0)
		{
			AddCurrentCarryBlocks(-WeaponItem.WeaponUpgradeWeight[NewUpgradeLevel-1]);
		}
		AddCurrentCarryBlocks(WeaponItem.WeaponUpgradeWeight[NewUpgradeLevel]);
	}
}

// reliable server final private function ServerBuyGrenade( int AmountPurchased )
private reliable server function CTI_ServerBuyGrenade(int AmountPurchased)
{
	if (Role != ROLE_Authority || !bServerTraderMenuOpen) return;

	if (CTI_ProcessGrenadeDosh(AmountPurchased))
	{
		AddGrenades(AmountPurchased);
	}
}

defaultproperties
{

}
