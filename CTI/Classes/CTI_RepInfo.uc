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

var private KFGFxWidget_PartyInGame PartyInGameWidget;
var private GFxObject               Notification;

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
	CTI                = _CTI;
	LogLevel            = _LogLevel;
	RemoveItems         = _RemoveItems;
	AddItems            = _AddItems;
	ReplaceMode         = _ReplaceMode;
	PreloadContent      = _PreloadContent;
	ForcePreloadContent = _ForcePreloadContent;
	SyncSize            = RemoveItems.Length + AddItems.Length;
}

private simulated function PlayerController GetPlayerController()
{
	local PlayerController PC;
	
	PC = PlayerController(Owner);
	
	if (PC == None && ROLE < ROLE_Authority)
	{
		PC = GetALocalPlayerController();
	}
	
	return PC;
}

private simulated function SetPartyInGameWidget()
{
	local KFPlayerController KFPC;
	
	`Log_Trace(`Location);
	
	KFPC = KFPlayerController(GetPlayerController());
	if (KFPC == None) return;
	if (KFPC.MyGFxManager == None) return;
	if (KFPC.MyGFxManager.PartyWidget == None) return;
	
	PartyInGameWidget = KFGFxWidget_PartyInGame(KFPC.MyGFxManager.PartyWidget);
	Notification = PartyInGameWidget.Notification;
}

private simulated function bool CheckPartyInGameWidget()
{
	if (PartyInGameWidget == None)
	{
		SetPartyInGameWidget();
	}
	
	return (PartyInGameWidget != None);
}

private simulated function HideReadyButton()
{
	if (CheckPartyInGameWidget())
	{
		PartyInGameWidget.SetReadyButtonVisibility(false);
	}
}

private simulated function ShowReadyButton()
{
	if (CheckPartyInGameWidget())
	{
		Notification.SetVisible(false);
		PartyInGameWidget.SetReadyButtonVisibility(true);
		PartyInGameWidget.UpdateReadyButtonText();
		PartyInGameWidget.UpdateReadyButtonVisibility();
	}
}

private reliable client function UpdateNotification(String Title, String Downloading, String Remainig, int Percent)
{
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
	}
	
	Recieved = RemoveItems.Length + AddItems.Length;
	
	UpdateNotification(
		"Sync items, please wait...",
		Remove ? "-" : "+" @ Repl(String(WeapDef), "KFWeapDef_", ""),
		Recieved @ "/" @ SyncSize,
		(float(Recieved) / float(SyncSize)) * 100);
	
	ServerSync();
}

private simulated reliable client function SyncFinished()
{
	local KFGameReplicationInfo KFGRI;
	
	`Log_Trace(`Location);
	
	if (WorldInfo == None || WorldInfo.GRI == None)
	{
		SetTimer(1.0f, false, nameof(SyncFinished));
		return;
	}
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ WorldInfo.GRI);
		SafeDestroy();
		return;
	}

	Helper.static.ModifyTrader(KFGRI, RemoveItems, AddItems, ReplaceMode);
	
	if (PreloadContent)
	{
		Helper.static.PreloadContent(AddItems);
	}

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
			PreloadContentWorkaround();
		}
		SyncFinished();
		if (!CTI.DestroyRepLink(Controller(Owner)))
		{
			SafeDestroy();
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

private function PreloadContentWorkaround()
{
	local PlayerController PC;
	local Pawn P;
	local KFInventoryManager KFIM;
	local class<Weapon> CW;
	local Weapon W;
	local int Index;
	local DroppedPickup DP;
	local float Time;
	
	`Log_Trace(`Location);

	PC = GetPlayerController();
	
	if (PC == None)
	{
		SetTimer(0.1f, false, nameof(PreloadContentWorkaround));
		return;
	}
	
	P = PC.Pawn;
	if (P == None)
	{
		SetTimer(0.1f, false, nameof(PreloadContentWorkaround));
		return;
	}
	
	KFIM = KFInventoryManager(P.InvManager);
	if (KFIM == None)
	{
		SetTimer(0.1f, false, nameof(PreloadContentWorkaround));
		return;
	}

	KFIM.bInfiniteWeight = true;
	Time = WorldInfo.TimeSeconds - 1.0f;

	for (Index = 0; Index < AddItems.Length; Index++)
	{
		UpdateNotification(
			"Game isn't frozen, Don't panic",
			"Preload content:",
			Index @ "/" @ AddItems.Length,
			(float(Index) / float(AddItems.Length)) * 100);
		
		CW = class<Weapon> (DynamicLoadObject(AddItems[Index].default.WeaponClassPath, class'Class'));
		if (CW != None && Weapon(P.FindInventoryType(CW)) == None)
		{
			P.CreateInventory(CW);
		}
	}
	
	UpdateNotification("Cleanup", "", "", 0);
			
	foreach KFIM.InventoryActors(class'Weapon', W)
	{
		if (W != None)
		{
			KFIM.PendingWeapon = W;
			KFIM.ChangedWeapon();
			if (W.CanThrow())
			{
				P.TossInventory(W);
				W.Destroy();
			}
		}
	}
	
	UpdateNotification("Cleanup", "", "", 0);
	
	foreach WorldInfo.DynamicActors(class'DroppedPickup', DP)
	{
		if (DP.Instigator == P && DP.CreationTime > Time)
		{
			DP.Destroy();
		}
	}
	
	KFIM.bInfiniteWeight = false;
	
	`Log_Info("Force Preload Finished (" $ PC.PlayerReplicationInfo.PlayerName $ ")");
}

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false
	
	PendingSync = false
	Recieved    = 0
}
