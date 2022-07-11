class CTI_RepInfo extends ReplicationInfo;

const Helper = class'Helper';

var public  bool PendingSync;

var private CTI CTI;
var private E_LogLevel LogLevel;
var private Array<class<KFWeaponDefinition> > RemoveItems;
var private Array<class<KFWeaponDefinition> > AddItems;
var private bool ReplaceMode;
var private bool PreloadContent;

var private int  Recieved;
var private int  SyncSize;

var private KFPlayerController      KFPC;
var private KFGFxWidget_PartyInGame PartyInGameWidget;
var private GFxObject               Notification;

var private String NotificationHeaderText;
var private String NotificationLeftText;
var private String NotificationRightText;
var private int    NotificationPercent;

var private int    WaitingGRI;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel, ReplaceMode, SyncSize;
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
	bool _ReplaceMode)
{
	`Log_Trace(`Location);
	
	CTI                 = _CTI;
	LogLevel            = _LogLevel;
	RemoveItems         = _RemoveItems;
	AddItems            = _AddItems;
	ReplaceMode         = _ReplaceMode;
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

private simulated function HideReadyButton()
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

private simulated function UpdateNotification(String Title, String Downloading, String Remainig, int Percent)
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
	
	if (!IsTimerActive(nameof(KeepNotification)))
	{
		SetTimer(0.1f, true, nameof(KeepNotification));
	}
	
	if (Remove)
	{
		RemoveItems.AddItem(WeapDef);
	}
	else
	{
		AddItems.AddItem(WeapDef);
	}
	
	Recieved = RemoveItems.Length + AddItems.Length;
	
	NotificationLeftText    = Remove ? "-" : "+" @ Repl(String(WeapDef), "KFWeapDef_", "");
	NotificationRightText   = Recieved @ "/" @ SyncSize;
	if (SyncSize != 0)
	{
		NotificationPercent = (float(Recieved) / float(SyncSize)) * 100;
	}
	
	`Log_Debug("ClientSync:" @ NotificationLeftText @ NotificationRightText);
	
	ServerSync();
}

private simulated function KeepNotification()
{
	HideReadyButton();
	UpdateNotification(
		NotificationHeaderText,
		NotificationLeftText,
		NotificationRightText,
		NotificationPercent);
}

private simulated reliable client function ClientSyncFinished()
{
	local KFGameReplicationInfo KFGRI;
	
	`Log_Trace(`Location);
	
	if (WorldInfo.GRI == None)
	{
		`Log_Debug("ClientSyncFinished: WorldInfo.GRI == None");
		NotificationHeaderText = "Waiting for GameReplicationInfo...";
		NotificationLeftText   = String(++WaitingGRI) $ "s";
		SetTimer(1.0f, false, nameof(ClientSyncFinished));
		return;
	}
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ WorldInfo.GRI);
		ClearTimer(nameof(KeepNotification));
		UpdateNotification(
			"Error: Incompatible Replication info:" @ WorldInfo.GRI,
			"", "", 0);
		SafeDestroy();
		return;
	}

	Helper.static.ModifyTrader(KFGRI, RemoveItems, AddItems, ReplaceMode);
	`Log_Debug("ClientSyncFinished: Helper.static.ModifyTrader");

	ClearTimer(nameof(KeepNotification)); 
	ShowReadyButton();
	
	SafeDestroy();
}

public reliable server function ServerSync()
{
	`Log_Trace(`Location);
	
	PendingSync = false;
	
	if (bPendingDelete || bDeleteMe) return;
	
	`Log_Debug("ServerSync:" @ Recieved @ "/" @ SyncSize);
	if (SyncSize <= Recieved || WorldInfo.NetMode == NM_StandAlone)
	{
		`Log_Debug("ServerSync: SyncFinished");
		
		ClientSyncFinished();
	
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

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false
	
	PendingSync = false
	Recieved    = 0
	
	NotificationHeaderText = "Sync trader items, please wait..."
	NotificationPercent    = 0
	
	WaitingGRI             = 0
}
