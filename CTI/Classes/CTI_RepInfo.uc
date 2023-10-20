class CTI_RepInfo extends ReplicationInfo
	dependson(WeaponReplacements);

const CAPACITY = 64; // max: 128

const Trader       = class'Trader';
const LocalMessage = class'CTI_LocalMessage';
const Replacements = class'WeaponReplacements';

struct ReplicationStruct
{
	var int Size;
	var int Transfered;

	var class<KFWeaponDefinition> Items[CAPACITY];
	var int Length;
};

var public  bool PendingSync;

var private CTI CTI;
var private E_LogLevel LogLevel;

var private KFPlayerController      KFPC;
var private KFPlayerReplicationInfo KFPRI;
var private KFGFxWidget_PartyInGame PartyInGameWidget;
var private GFxObject               Notification;

var private String NotificationHeaderText;
var private String NotificationLeftText;
var private String NotificationRightText;
var private int    NotificationPercent;

var private int    WaitingGRI;
var private int    WaitingGRILimit;

var private ReplicationStruct                 RepData;
var private Array<class<KFWeaponDefinition> > RepArray;

var private bool SkinUpdateRequired;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel, SkinUpdateRequired;
}

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public function Replicate(const out Array<class<KFWeaponDefinition> > WeapDefs)
{
	`Log_Trace();

	RepArray = WeapDefs;
	RepData.Size = RepArray.Length;

	if (WorldInfo.NetMode == NM_StandAlone)
	{
		Progress(RepArray.Length, RepArray.Length);
		return;
	}

	Sync();
}

private reliable server function Sync()
{
	local int  LocalIndex;
	local int  GlobalIndex;

	`Log_Trace();

	LocalIndex = 0;
	GlobalIndex = RepData.Transfered;

	while (LocalIndex < CAPACITY && GlobalIndex < RepData.Size)
	{
		RepData.Items[LocalIndex++] = RepArray[GlobalIndex++];
	}

	if (RepData.Transfered == GlobalIndex) return; // Finished

	RepData.Transfered = GlobalIndex;
	RepData.Length = LocalIndex;

	Send(RepData);

	Progress(RepData.Transfered, RepData.Size);
}

private reliable client function Send(ReplicationStruct RD)
{
	local int LocalIndex;

	`Log_Trace();

	for (LocalIndex = 0; LocalIndex < RD.Length; LocalIndex++)
	{
		RepArray.AddItem(RD.Items[LocalIndex]);
	}

	Progress(RD.Transfered, RD.Size);

	Sync();
}

public function PrepareSync(CTI _CTI, KFPlayerController _KFPC, E_LogLevel _LogLevel, bool _SkinUpdateRequired)
{
	`Log_Trace();

	CTI                = _CTI;
	KFPC               = _KFPC;
	LogLevel           = _LogLevel;
	SkinUpdateRequired = _SkinUpdateRequired;
}

private simulated function Progress(int Value, int Size)
{
	`Log_Trace();

	`Log_Debug("Replicated:" @ Value @ "/" @ Size);

	if (ROLE < ROLE_Authority)
	{
		NotifyProgress(Value, Size);
		if (Value >= Size) Finished();
	}
}

private simulated function Finished()
{
	local KFGameReplicationInfo KFGRI;

	`Log_Trace();

	if (WorldInfo.GRI == None && WaitingGRI++ < WaitingGRILimit)
	{
		`Log_Debug("Finished: Waiting GRI" @ WaitingGRI);
		NotifyWaitingGRI();
		SetTimer(1.0f, false, nameof(Finished));
		return;
	}

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None)
	{
		`Log_Debug("Finished: Trader.static.OverwriteTraderItems");
		Trader.static.OverwriteTraderItems(KFGRI, RepArray, LogLevel);
		`Log_Info("Trader items successfully synchronized!");
	}
	else
	{
		`Log_Error("Incompatible Replication info:" @ String(WorldInfo.GRI));
		NotifyIncompatibleGRI();
	}

	ShowReadyButton();

	if (SkinUpdateRequired)
	{
		SetTimer(1.0f, true, nameof(UpdateSkinsDLC));
	}
	else
	{
		ClientCleanup();
	}
}

private simulated function UpdateSkinsDLC()
{
	local SWeapReplace WeapReplace;

	`Log_Debug("Wait for spawn");
	if (GetKFPRI() != None && KFPRI.bHasSpawnedIn)
	{
		foreach Replacements.default.DLC(WeapReplace)
		{
			if (WeapReplace.WeapParent.default.SkinItemId > 0 && WeapReplace.Weap.default.SkinItemId != WeapReplace.WeapParent.default.SkinItemId)
			{
				`Log_Debug("Update skin for:" @ String(WeapReplace.WeapDef) @ "SkinId:" @ WeapReplace.WeapParent.default.SkinItemId);
				class'KFWeaponSkinList'.static.SaveWeaponSkin(WeapReplace.WeapDef, WeapReplace.WeapParent.default.SkinItemId);
			}
		}

		ClearTimer(nameof(UpdateSkinsDLC));
		ClientCleanup();
	}
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

private simulated function KFPlayerReplicationInfo GetKFPRI()
{
	`Log_Trace();

	if (KFPRI != None) return KFPRI;

	if (GetKFPC() == None) return None;

	KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);

	return KFPRI;
}

public reliable client function WriteToChatLocalized(
	E_CTI_LocalMessageType LMT,
	optional String HexColor,
	optional String String1,
	optional String String2,
	optional String String3)
{
	`Log_Trace();

	WriteToChat(LocalMessage.static.GetLocalizedString(LogLevel, LMT, String1, String2, String3), HexColor);
}

public reliable client function WriteToChat(String Message, optional String HexColor)
{
	local KFGFxHudWrapper HUD;

	`Log_Trace();

	if (GetKFPC() == None) return;

	if (KFPC.MyGFxManager.PartyWidget != None && KFPC.MyGFxManager.PartyWidget.PartyChatWidget != None)
	{
		KFPC.MyGFxManager.PartyWidget.PartyChatWidget.SetVisible(true);
		KFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(Message, HexColor);
	}

	HUD = KFGFxHudWrapper(KFPC.myHUD);
	if (HUD != None && HUD.HUDMovie != None && HUD.HUDMovie.HudChatBox != None)
	{
		HUD.HUDMovie.HudChatBox.AddChatMessage(Message, HexColor);
	}
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

	ClearTimer(nameof(KeepNotification));

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

private simulated function KeepNotification()
{
	HideReadyButton();
	UpdateNotification(
		NotificationHeaderText,
		NotificationLeftText,
		NotificationRightText,
		NotificationPercent);
}

private simulated function ClientCleanup()
{
	`Log_Debug("Cleanup");
	ServerCleanup();
	SafeDestroy();
}

private reliable server function ServerCleanup()
{
	`Log_Trace();

	`Log_Debug("Cleanup" @ GetKFPC() @ GetKFPRI() == None? "" : GetKFPRI().PlayerName);
	if (!CTI.DestroyRepInfo(GetKFPC()))
	{
		`Log_Debug("Cleanup (forced)");
		SafeDestroy();
	}
}

private simulated function NotifyWaitingGRI()
{
	if (!IsTimerActive(nameof(KeepNotification)))
	{
		SetTimer(0.1f, true, nameof(KeepNotification));
	}

	NotificationHeaderText = LocalMessage.static.GetLocalizedString(LogLevel, CTI_WaitingGRI);
	NotificationLeftText   = String(WaitingGRI) $ LocalMessage.static.GetLocalizedString(LogLevel, CTI_SecondsShort);
	NotificationRightText  = LocalMessage.static.GetLocalizedString(LogLevel, CTI_PleaseWait);
	NotificationPercent    = 0;
	KeepNotification();
}

private simulated function NotifyProgress(int Value, int Size)
{
	if (!IsTimerActive(nameof(KeepNotification)))
	{
		SetTimer(0.1f, true, nameof(KeepNotification));
	}

	NotificationHeaderText  = LocalMessage.static.GetLocalizedString(LogLevel, CTI_SyncItems);
	NotificationLeftText    = Value @ "/" @ Size;
	NotificationRightText   = LocalMessage.static.GetLocalizedString(LogLevel, CTI_PleaseWait);
	NotificationPercent     = (float(Value) / float(Size)) * 100;
	KeepNotification();
}

private simulated function NotifyIncompatibleGRI()
{
	WriteToChatLocalized(
		CTI_IncompatibleGRI,
		class'KFLocalMessage'.default.InteractionColor,
		String(WorldInfo.GRI.class));
	WriteToChatLocalized(
		CTI_IncompatibleGRIWarning,
		class'KFLocalMessage'.default.InteractionColor);
}

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false

	PendingSync = false

	NotificationPercent    = 0
	WaitingGRI             = 0
	WaitingGRILimit        = 30
}
