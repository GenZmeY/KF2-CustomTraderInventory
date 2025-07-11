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

class CTI_RepInfo extends ReplicationInfo
	dependson(WeaponReplacements);

const CAPACITY = 64; // max: 128

const Trader             = class'Trader';
const LocalMessage       = class'CTI_LocalMessage';
const Replacements       = class'WeaponReplacements';
const PurchaseHelper     = class'CTI_AutoPurchaseHelper';
const InventoryManager   = class'CTI_InventoryManager';

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

var private class<KFGFxMoviePlayer_Manager> FrontEndClass;

var private GameReplicationInfo     GRI;
var private KFPlayerController      KFPC;
var private KFPlayerReplicationInfo KFPRI;
var private KFGFxWidget_PartyInGame PartyInGameWidget;
var private GFxObject               Notification;

var private String NotificationHeaderText;
var private String NotificationLeftText;
var private String NotificationRightText;
var private int    NotificationPercent;

var private int    WaitingGRI;
var private int    WaitingGRIThreshold;
var private int    WaitingGRILimit;

var private ReplicationStruct                 RepData;
var private Array<class<KFWeaponDefinition> > RepArray;

var private bool SkinUpdateRequired;
var private bool PatchRequired;

var private bool ClientReady, ServerReady;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel, SkinUpdateRequired, PatchRequired, FrontEndClass;
}

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public function PrepareSync(
	CTI _CTI, E_LogLevel _LogLevel,
	class<KFGFxMoviePlayer_Manager> _FrontEndClass,
	bool _SkinUpdateRequired, bool _PatchRequired)
{
	`Log_Trace();

	CTI                      = _CTI;
	LogLevel                 = _LogLevel;
	FrontEndClass            = _FrontEndClass;
	SkinUpdateRequired       = _SkinUpdateRequired;
	PatchRequired            = _PatchRequired;
}

private reliable client function ClientSetFrontEnd()
{
	if (FrontEndClass == None || GetKFPRI() == None)
	{
		`Log_Debug("Wait for frontend");
		SetTimer(1.0f, false, nameof(ClientSetFrontEnd));
		return;
	}

	if (KFPC.MyGFxManager != None && KFPC.MyGFxManager.class == FrontEndClass)
	{
		`Log_Debug("MyGFxManager is ok:" @ String(KFPC.MyGFxManager.class));
		return;
	}

	KFPC.MyGFxManager.CloseMenus(true);
	KFPC.MyGFxManager = None;

	KFPC.ClientSetFrontEnd(FrontEndClass, KFPRI.bOnlySpectator);

	`Log_Debug(String(FrontEndClass) @ "initialized.");
}

public function Replicate(const out Array<class<KFWeaponDefinition> > WeapDefs)
{
	`Log_Trace();

	ServerReady = !PatchRequired;

	ClientSetFrontEnd();

	if (PatchRequired)
	{
		if (GetKFPC() != None)
		{
			KFPC.PurchaseHelperClass = PurchaseHelper;
			KFPC.PurchaseHelper = None;
		}

		InitInventoryManager();
	}

	RepArray = WeapDefs;
	RepData.Size = RepArray.Length;

	if (WorldInfo.NetMode != NM_StandAlone)
	{
		Sync();
	}
	else
	{
		Finished();
	}
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

	if ((GetGRI(WaitingGRI > WaitingGRIThreshold) == None) && WaitingGRI++ < WaitingGRILimit)
	{
		`Log_Debug("Finished: Waiting GRI" @ WaitingGRI);
		NotifyWaitingGRI();
		SetTimer(1.0f, false, nameof(Finished));
		return;
	}

	if (PatchRequired && GetKFPC() != None)
	{
		KFPC.PurchaseHelperClass = PurchaseHelper;
		KFPC.PurchaseHelper = None;
	}

	KFGRI = KFGameReplicationInfo(GRI);
	if (KFGRI != None)
	{
		`Log_Debug("Finished: Trader.static.OverwriteTraderItems");
		if (WorldInfo.NetMode != NM_StandAlone)
		{
			Trader.static.OverwriteTraderItems(KFGRI, RepArray, PatchRequired, LogLevel);
		}
		`Log_Info("Trader items successfully synchronized!");
	}
	else
	{
		`Log_Error("Incompatible Game Replication info:" @ String(GRI));
		if (GRI == None)
		{
			NotifyNoneGRI();
		}
		else
		{
			NotifyIncompatibleGRI();
		}
	}

	ShowReadyButton();

	if (SkinUpdateRequired)
	{
		SkinUpdate();
	}
	else
	{
		ClientFinished();
	}
}

private simulated function SkinUpdate()
{
	local SWeapReplace WeapReplace;

	if (GetKFPRI() == None || !KFPRI.bHasSpawnedIn)
	{
		`Log_Debug("Wait for spawn (SkinUpdate)");
		SetTimer(1.0f, false, nameof(SkinUpdate));
		return;
	}

	foreach Replacements.default.DLC(WeapReplace)
	{
		// sometimes "WeapReplace.Weap.default.SkinItemId" can give values greater than zero while actually being zero
		// this is the same bug that prevents creating the correct default config
		// so for now let’s shorten the check a little so that the skinId of the WeapReplace is guaranteed to be correct
		// but if this bug is ever fixed, then it’s worth replacing the check with this one:
		// if (WeapReplace.WeapParent.default.SkinItemId > 0 && WeapReplace.Weap.default.SkinItemId != WeapReplace.WeapParent.default.SkinItemId)
		// to reduce the number of meaningless disk writes
		if (WeapReplace.WeapParent.default.SkinItemId > 0)
		{
			`Log_Debug("Update skin for:" @ String(WeapReplace.WeapDef) @ "SkinId:" @ WeapReplace.WeapParent.default.SkinItemId);
			class'KFWeaponSkinList'.static.SaveWeaponSkin(WeapReplace.WeapDef, WeapReplace.WeapParent.default.SkinItemId);
		}
	}

	ClearTimer(nameof(SkinUpdate));
	ClientFinished();
}

private simulated function GameReplicationInfo GetGRI(optional bool ForcedSearch = false)
{
	`Log_Trace();

	if (GRI == None)
	{
		GRI = WorldInfo.GRI;
	}

	if (GRI == None && ForcedSearch)
	{
		foreach WorldInfo.DynamicActors(class'GameReplicationInfo', GRI) break;
	}

	if (WorldInfo.GRI == None && GRI != None)
	{
		`Log_Warn("Force initialization of WorldInfo.GRI" @ String(GRI));
		WorldInfo.GRI = GRI;
	}

	return GRI;
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

private reliable server function ClientFinished()
{
	ClientReady = true;
	if (ClientReady && ServerReady) Cleanup();
}

private function ServerFinished()
{
	ServerReady = true;
	if (ClientReady && ServerReady) Cleanup();
}

private reliable server function Cleanup()
{
	`Log_Trace();

	if (PatchRequired)
	{
		`Log_Debug("Skip cleanup to keep CTI_RepInfo alive");
		return;
	}

	`Log_Debug("Cleanup" @ GetKFPC() @ GetKFPRI() == None? "" : GetKFPRI().PlayerName);
	if (!CTI.DestroyRepInfo(GetKFPC()))
	{
		`Log_Debug("Cleanup (forced)");
		SafeDestroy();
	}
}

public function InitInventoryManager()
{
	local InventoryManager PrevInventoryManger;
	local InventoryManager NextInventoryManger;

	local KFInventoryManager PrevKFInventoryManger;
	local KFInventoryManager NextKFInventoryManger;

	local Inventory Item;

	`Log_Trace();

	if (GetKFPRI() == None || !KFPRI.bHasSpawnedIn || KFPC.Pawn == None)
	{
		`Log_Debug("Wait for spawn (InventoryManager)");
		SetTimer(1.0f, false, nameof(InitInventoryManager));
		return;
	}

	PrevInventoryManger = KFPC.Pawn.InvManager;

	KFPC.Pawn.InventoryManagerClass = InventoryManager;
	NextInventoryManger = Spawn(KFPC.Pawn.InventoryManagerClass, KFPC.Pawn);
	CTI_InventoryManager(NextInventoryManger).Initialize(Self);

	if (NextInventoryManger == None)
	{
		`Log_Error("Can't spawn" @ String(KFPC.Pawn.InventoryManagerClass));
		ServerFinished();
		return;
	}

	KFPC.Pawn.InvManager = NextInventoryManger;
	KFPC.Pawn.InvManager.SetupFor(KFPC.Pawn);

	if (PrevInventoryManger == None)
	{
		KFPC.Pawn.AddDefaultInventory();
	}
	else
	{
		for (Item = PrevInventoryManger.InventoryChain; Item != None; Item = PrevInventoryManger.InventoryChain)
		{
			PrevInventoryManger.RemoveFromInventory(Item);
			NextInventoryManger.AddInventory(Item);
		}
	}

	PrevKFInventoryManger = KFInventoryManager(PrevInventoryManger);
	NextKFInventoryManger = KFInventoryManager(NextInventoryManger);

	if (PrevKFInventoryManger != None && NextKFInventoryManger != None)
	{
		NextKFInventoryManger.GrenadeCount = PrevKFInventoryManger.GrenadeCount;
	}

	PrevKFInventoryManger.InventoryChain = None;
	PrevKFInventoryManger.Destroy();

	`Log_Debug("InventoryManager initialized");

	ServerFinished();
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
		String(GRI.class));
	WriteToChatLocalized(
		CTI_IncompatibleGRIWarning,
		class'KFLocalMessage'.default.InteractionColor);
}

private simulated function NotifyNoneGRI()
{
	WriteToChatLocalized(
		CTI_NoneGRI,
		class'KFLocalMessage'.default.InteractionColor);
	WriteToChatLocalized(
		CTI_NoneGRIWarning,
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
	WaitingGRIThreshold    = 15
	WaitingGRILimit        = 30

	ClientReady = false
	ServerReady = false
}
