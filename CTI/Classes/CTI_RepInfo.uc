class CTI_RepInfo extends ReplicationInfo;

const Helper = class'Helper';

var public  bool PendingSync;

var private CTI CTI;
var private E_LogLevel LogLevel;
var private Array<class<KFWeaponDefinition> > RemoveItems;
var private Array<class<KFWeaponDefinition> > AddItems;
var private bool ReplaceMode;
var private bool PreloadContent;
var private bool ForcePreloadContent;

var private int  Recieved;
var private int  SyncSize;
var private int  Preloaded;

var private KFPlayerController      KFPC;
var private KFPawn                  KFP;
var private KFInventoryManager      KFIM;

var private KFGFxWidget_PartyInGame PartyInGameWidget;
var private GFxObject               Notification;

var private class<Weapon>           PreloadWeaponClass;
var private float                   PreloadWeaponTime;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel, ReplaceMode, PreloadContent, ForcePreloadContent, SyncSize;
}

public simulated function bool SafeDestroy()
{
	`Log_Trace(`Location);
	
	return (bPendingDelete || bDeleteMe || Destroy());
}

public function PrepareSync(
	CTI _CTI,
	E_LogLevel _LogLevel,
	Array<class<KFWeaponDefinition> > _RemoveItems,
	Array<class<KFWeaponDefinition> > _AddItems,
	bool _ReplaceMode,
	bool _PreloadContent,
	bool _ForcePreloadContent)
{
	`Log_Trace(`Location);
	
	CTI                 = _CTI;
	LogLevel            = _LogLevel;
	RemoveItems         = _RemoveItems;
	AddItems            = _AddItems;
	ReplaceMode         = _ReplaceMode;
	PreloadContent      = _PreloadContent;
	ForcePreloadContent = _ForcePreloadContent;
	SyncSize            = RemoveItems.Length + AddItems.Length;
}

private simulated function KFPlayerController GetKFPC()
{
	`Log_Trace(`Location);
	
	if (KFPC != None) return KFPC;
	
	KFPC = KFPlayerController(Owner);
	
	if (KFPC == None && ROLE < ROLE_Authority)
	{
		KFPC = KFPlayerController(GetALocalPlayerController());
	}
	
	return KFPC;
}

private simulated function KFPawn GetKFP()
{
	local Pawn P;
	
	`Log_Trace(`Location);
	
	if (KFP != None) return KFP;
	
	if (GetKFPC() != None)
	{
		P = GetKFPC().Pawn;
		if (P != None)
		{
			KFP = KFPawn(P);
		}
	}

	return KFP;
}

private simulated function KFInventoryManager GetKFIM()
{
	local InventoryManager IM;
	
	`Log_Trace(`Location);
	
	if (KFIM != None) return KFIM;
	
	if (GetKFP() != None)
	{
		IM = GetKFP().InvManager;
		if (IM != None)
		{
			KFIM = KFInventoryManager(IM);
		}
	}
	
	return KFIM;
}

private simulated function SetPartyInGameWidget()
{
	`Log_Trace(`Location);
	
	if (GetKFPC() == None) return;
	
	if (KFPC.MyGFxManager == None) return;
	if (KFPC.MyGFxManager.PartyWidget == None) return;
	
	PartyInGameWidget = KFGFxWidget_PartyInGame(KFPC.MyGFxManager.PartyWidget);
	Notification = PartyInGameWidget.Notification;
}

private simulated function bool CheckPartyInGameWidget()
{
	`Log_Trace(`Location);
	
	if (PartyInGameWidget == None)
	{
		SetPartyInGameWidget();
	}
	
	return (PartyInGameWidget != None);
}

private unreliable client function HideReadyButton()
{
	`Log_Trace(`Location);
	
	if (CheckPartyInGameWidget())
	{
		PartyInGameWidget.SetReadyButtonVisibility(false);
	}
}

private simulated function ShowReadyButton()
{
	`Log_Trace(`Location);
	
	if (CheckPartyInGameWidget())
	{
		Notification.SetVisible(false);
		PartyInGameWidget.SetReadyButtonVisibility(true);
		PartyInGameWidget.UpdateReadyButtonText();
		PartyInGameWidget.UpdateReadyButtonVisibility();
	}
}

private unreliable client function UpdateNotification(String Title, String Downloading, String Remainig, int Percent)
{
	`Log_Trace(`Location);
	
	if (CheckPartyInGameWidget() && Notification != None)
	{
		Notification.SetString("itemName", Title);
		Notification.SetFloat("percent", Percent);
		Notification.SetInt("queue", 0);
		Notification.SetString("downLoading", Downloading);
		Notification.SetString("remaining", Remainig);
		Notification.SetObject("notificationInfo", Notification);
		Notification.SetVisible(true);
	}
}

private reliable client function ClientSync(class<KFWeaponDefinition> WeapDef, optional bool Remove = false)
{
	`Log_Trace(`Location);
	
	if (WeapDef == None)
	{
		`Log_Fatal("WeapDef is:" @ WeapDef);
		SafeDestroy();
		return;
	}
	
	HideReadyButton();

	if (Remove)
	{
		RemoveItems.AddItem(WeapDef);
	}
	else
	{
		AddItems.AddItem(WeapDef);
		if (PreloadContent)
		{
			Helper.static.PreloadWeapon(WeapDef);
		}
	}
	
	Recieved = RemoveItems.Length + AddItems.Length;
	
	UpdateNotification(
		"Sync trader items, please wait...",
		Remove ? "-" : "+" @ Repl(String(WeapDef), "KFWeapDef_", ""),
		Recieved @ "/" @ SyncSize,
		(float(Recieved) / float(SyncSize)) * 100);
	
	ServerSync();
}

private simulated reliable client function ClientSyncFinished()
{
	local KFGameReplicationInfo KFGRI;
	
	`Log_Trace(`Location);
	
	ClearTimer(nameof(KeepPreloadNotification)); 
	ClearTimer(nameof(WaitForPreloadWeapon)); 
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ WorldInfo.GRI);
		SafeDestroy();
		return;
	}

	Helper.static.ModifyTrader(KFGRI, RemoveItems, AddItems, ReplaceMode);

	ShowReadyButton();
	
	SafeDestroy();
}

public reliable server function ServerSync()
{
	`Log_Trace(`Location);
	
	PendingSync = false;
	
	if (bPendingDelete || bDeleteMe) return;
	
	if (SyncSize <= Recieved || WorldInfo.NetMode == NM_StandAlone)
	{
		if (ForcePreloadContent)
		{
			ServerPreloadWeaponWorkaround();
		}
		else
		{
			ServerSyncFinished();
		}
	}
	else
	{
		if (Recieved < RemoveItems.Length)
		{
			ClientSync(RemoveItems[Recieved++], true);
		}
		else
		{
			ClientSync(AddItems[Recieved++ - RemoveItems.Length], false);
		}
	}
}

private function ServerSyncFinished()
{
	`Log_Trace(`Location);
	
	ClientSyncFinished();
	
	if (!CTI.DestroyRepLink(Controller(Owner)))
	{
		SafeDestroy();
	}
}

private reliable server function ServerPreloadWeaponWorkaround()
{
	local class<Weapon> WC;
	
	`Log_Trace(`Location);
	
	RemovePreloadWeapon();

	if (AddItems.Length <= Preloaded)
	{
		ServerSyncFinished();
	}
	else
	{
		WC = class<Weapon> (DynamicLoadObject(AddItems[Preloaded++].default.WeaponClassPath, class'Class'));
		if (WC != None)
		{
			PreloadWeaponTime = WorldInfo.TimeSeconds - 1.0f;
			PreloadWeaponClass = WC;
			ClientPreloadWeapon(WC);
			if (!AddPreloadWeapon(WC))
			{
				ServerPreloadWeaponWorkaround();
			}
		}
	}
}

private reliable server function bool AddPreloadWeapon(class<Weapon> WC)
{
	local Weapon W;
	
	`Log_Trace(`Location);
	
	if (GetKFIM() == None || WC == None) return false;
	
	KFIM.bInfiniteWeight = true;
	W = Weapon(KFP.FindInventoryType(WC));
	if (W == None)
	{
		W = Weapon(KFP.CreateInventory(WC));
	}
	
	if (W != None)
	{
		KFIM.SetCurrentWeapon(W);
	}
	KFIM.bInfiniteWeight = false;
	
	if (W == None) `Log_Warn("Can't preload" @ WC @ "for some reason (skip)");
	
	return (W != None);
}

private function RemovePreloadWeapon()
{
	local DroppedPickup DP;
	local Weapon W;
	
	`Log_Trace(`Location);
	
	if (GetKFIM() == None || PreloadWeaponClass == None) return;
	
	foreach KFIM.InventoryActors(class'Weapon', W)
	{
		if (W != None && W.class == PreloadWeaponClass)
		{
			if (W.CanThrow())
			{
				KFP.TossInventory(W);
				W.Destroy();
			}
		}
	}
	
	foreach WorldInfo.DynamicActors(class'DroppedPickup', DP)
	{
		if (DP.Instigator == KFP && DP.CreationTime > PreloadWeaponTime)
		{
			DP.Destroy();
		}
	}
}

private reliable client function ClientPreloadWeapon(class<Weapon> WC)
{
	`Log_Trace(`Location);
	
	Preloaded++;
	PreloadWeaponClass = WC;
	
	if (!IsTimerActive(nameof(KeepPreloadNotification)))
	{
		SetTimer(0.1f, true, nameof(KeepPreloadNotification));
	}
	
	SetTimer(0.5f, false, nameof(WaitForPreloadWeapon));
}

private simulated function KeepPreloadNotification()
{
	HideReadyButton();
	UpdateNotification(
		"Preload weapon models, please wait...",
		Repl(String(PreloadWeaponClass), "KFWeap_", ""),
		Preloaded @ "/" @ AddItems.Length,
		(float(Preloaded) / float(AddItems.Length)) * 100);
}

private simulated function WaitForPreloadWeapon()
{
	`Log_Trace(`Location);
	
	KeepPreloadNotification();
	
	if (GetKFIM() != None
	&& KFIM.Instigator.Weapon != None
	&& KFIM.Instigator.Weapon.Class == PreloadWeaponClass)
	{
		ServerPreloadWeaponWorkaround();
	}
	else
	{
		SetTimer(0.5f, false, nameof(WaitForPreloadWeapon));
	}
}

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false
	
	PendingSync = false
	Recieved    = 0
	Preloaded   = 0
}
