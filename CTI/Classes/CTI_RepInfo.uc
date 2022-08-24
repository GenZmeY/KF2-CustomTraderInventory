class CTI_RepInfo extends ReplicationInfo;

const Trader       = class'Trader';
const LocalMessage = class'CTI_LocalMessage';

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
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public function PrepareSync(
	CTI _CTI,
	E_LogLevel _LogLevel,
	Array<class<KFWeaponDefinition> > _RemoveItems,
	Array<class<KFWeaponDefinition> > _AddItems,
	bool _ReplaceMode)
{
	`Log_Trace();
	
	CTI                 = _CTI;
	LogLevel            = _LogLevel;
	RemoveItems         = _RemoveItems;
	AddItems            = _AddItems;
	ReplaceMode         = _ReplaceMode;
	SyncSize            = RemoveItems.Length + AddItems.Length;
}

private simulated function KFPlayerController GetKFPC()
{
	`Log_Trace();
	
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
	`Log_Trace();
	
	if (GetKFPC() == None) return;
	
	if (KFPC.MyGFxManager == None) return;
	if (KFPC.MyGFxManager.PartyWidget == None) return;
	
	PartyInGameWidget = KFGFxWidget_PartyInGame(KFPC.MyGFxManager.PartyWidget);
	Notification = PartyInGameWidget.Notification;
}

private simulated function bool CheckPartyInGameWidget()
{
	`Log_Trace();
	
	if (PartyInGameWidget == None)
	{
		SetPartyInGameWidget();
	}
	
	return (PartyInGameWidget != None);
}

private simulated function HideReadyButton()
{
	`Log_Trace();
	
	if (CheckPartyInGameWidget())
	{
		PartyInGameWidget.SetReadyButtonVisibility(false);
	}
}

private simulated function ShowReadyButton()
{
	`Log_Trace();
	
	if (CheckPartyInGameWidget())
	{
		Notification.SetVisible(false);
		PartyInGameWidget.SetReadyButtonVisibility(true);
		PartyInGameWidget.UpdateReadyButtonText();
		PartyInGameWidget.UpdateReadyButtonVisibility();
	}
}

private simulated function UpdateNotification(String Title, String Left, String Right, int Percent)
{
	`Log_Trace();
	
	if (CheckPartyInGameWidget() && Notification != None)
	{
		Notification.SetString("itemName", Title);
		Notification.SetFloat("percent", Percent);
		Notification.SetInt("queue", 0);
		Notification.SetString("downLoading", Left);
		Notification.SetString("remaining", Right);
		Notification.SetObject("notificationInfo", Notification);
		Notification.SetVisible(true);
	}
}

private reliable client function ClientSync(class<KFWeaponDefinition> WeapDef, optional bool Remove = false)
{
	`Log_Trace();

	if (WeapDef == None)
	{
		`Log_Fatal("WeapDef is:" @ WeapDef);
		Cleanup();
		ConsoleCommand("Disconnect");
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
	
	NotificationHeaderText  = (Remove ? "-" : "+") @ WeapDef.static.GetItemName();
	NotificationLeftText    = LocalMessage.static.GetLocalizedString(LogLevel, CTI_SyncItems);
	NotificationRightText   = Recieved @ "/" @ SyncSize;
	if (SyncSize != 0)
	{
		NotificationPercent = (float(Recieved) / float(SyncSize)) * 100;
	}
	
	`Log_Debug("ClientSync:" @ (Remove ? "-" : "+") @ String(WeapDef) @ NotificationRightText);
	
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

	`Log_Trace();
	
	NotificationLeftText  = "";
	NotificationRightText = "";
	NotificationPercent   = 0;
	
	if (WorldInfo.GRI == None)
	{
		`Log_Debug("ClientSyncFinished: Waiting GRI");
		NotificationHeaderText = LocalMessage.static.GetLocalizedString(LogLevel, CTI_WaitingGRI);
		NotificationLeftText   = String(++WaitingGRI) $ LocalMessage.static.GetLocalizedString(LogLevel, CTI_SecondsShort);
		NotificationRightText  = "";
		SetTimer(1.0f, false, nameof(ClientSyncFinished));
		return;
	}
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ String(WorldInfo.GRI));
		ClearTimer(nameof(KeepNotification));
		UpdateNotification(
			LocalMessage.static.GetLocalizedString(LogLevel, CTI_IncompatibleGRI) @ String(WorldInfo.GRI),
			LocalMessage.static.GetLocalizedString(LogLevel, CTI_Disconnect), "", 0);
		Cleanup();
		ConsoleCommand("Disconnect");
		SafeDestroy();
		return;
	}
	
	NotificationHeaderText = LocalMessage.static.GetLocalizedString(LogLevel, CTI_SyncFinished);
	NotificationLeftText   = "";
	NotificationRightText  = "";
	NotificationPercent    = 0;

	Trader.static.ModifyTrader(KFGRI, RemoveItems, AddItems, ReplaceMode, LogLevel);
	`Log_Debug("ClientSyncFinished: Trader.static.ModifyTrader");

	ClearTimer(nameof(KeepNotification)); 
	ShowReadyButton();
	
	Cleanup();
	
	SafeDestroy();
}

private reliable server function Cleanup()
{
	`Log_Trace();
	
	`Log_Debug("Cleanup");
	if (!CTI.DestroyRepInfo(Controller(Owner)))
	{
		`Log_Debug("Cleanup (forced)");
		SafeDestroy();
	}
}

public reliable server function ServerSync()
{
	`Log_Trace();
	
	PendingSync = false;
	
	if (bPendingDelete || bDeleteMe) return;
	
	if (SyncSize <= Recieved || WorldInfo.NetMode == NM_StandAlone)
	{
		`Log_Debug("ServerSync: Finished");
		ClientSyncFinished();
	}
	else
	{
		if (Recieved < RemoveItems.Length)
		{
			`Log_Debug("ServerSync[-]:" @ (Recieved + 1) @ "/" @ SyncSize @ RemoveItems[Recieved]);
			ClientSync(RemoveItems[Recieved++], true);
		}
		else
		{
			`Log_Debug("ServerSync[+]:" @ (Recieved + 1) @ "/" @ SyncSize @ AddItems[Recieved - RemoveItems.Length]);
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
	
	NotificationPercent    = 0
	WaitingGRI             = 0
}
