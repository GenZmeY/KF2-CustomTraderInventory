class CTI extends Info
	config(CTI);

const LatestVersion = 5;

const CfgRemoveItems     = class'RemoveItems';
const CfgAddItems        = class'AddItems';
const CfgOfficialWeapons = class'OfficialWeapons';
const Trader             = class'Trader';
const Unlocker           = class'Unlocker';

struct S_PreloadContent
{
	var class<KFWeaponDefinition> KFWD;
	var class<KFWeapon>           KFWC;
	var KFWeapon                  KFW;
	var KFW_Access                KFWA;
};

var private config int        Version;
var private config E_LogLevel LogLevel;
var private config String     UnlockDLC;
var private config bool       bPreloadContent;
var private config bool       bOfficialWeaponsList;
var private config bool       bDisableItemLimitCheck;
var private config bool       bApplyPatch;

var private KFGameInfo            KFGI;
var private KFGameReplicationInfo KFGRI;

var private Array<class<KFWeaponDefinition> > WeapDefs;
var private Array<class<KFWeaponDefinition> > RemoveItems;
var private Array<class<KFWeaponDefinition> > AddItems;

var private Array<CTI_RepInfo> RepInfos;

var private bool ReadyToSync;

// To bypass "Booleans may not be out parameters" error
struct BoolWrapper
{
	var bool Value;

	structdefaultproperties
	{
		Value = false
	}
};

var private BoolWrapper DLCSkinUpdateRequired;

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	`Log_Trace();

	`Log_Debug("PreBeginPlay readyToSync" @ ReadyToSync);

	if (WorldInfo.NetMode == NM_Client)
	{
		`Log_Fatal("NetMode == NM_Client, Destroy...");
		SafeDestroy();
		return;
	}

	Super.PreBeginPlay();

	PreInit();
}

public event PostBeginPlay()
{
	`Log_Trace();

	if (bPendingDelete || bDeleteMe) return;

	Super.PostBeginPlay();

	PostInit();
}

private function PreInit()
{
	`Log_Trace();

	if (Version == `NO_CONFIG)
	{
		LogLevel = LL_Info;
		bPreloadContent = true;
		UnlockDLC = "False";
		SaveConfig();
	}

	CfgRemoveItems.static.InitConfig(Version, LatestVersion);
	CfgAddItems.static.InitConfig(Version, LatestVersion);

	switch (Version)
	{
		case `NO_CONFIG:
			`Log_Info("Config created");

		case 1:
			bOfficialWeaponsList = false;

		case 2:
		case 3:
			bDisableItemLimitCheck = false;

		case 4:
			bApplyPatch = false;

		case MaxInt:
			`Log_Info("Config updated to version" @ LatestVersion);
			break;

		case LatestVersion:
			`Log_Info("Config is up-to-date");
			break;

		default:
			`Log_Warn("The config version is higher than the current version (are you using an old mutator?)");
			`Log_Warn("Config version is" @ Version @ "but current version is" @ LatestVersion);
			`Log_Warn("The config version will be changed to" @ LatestVersion);
			break;
	}

	CfgOfficialWeapons.static.Update(bOfficialWeaponsList);

	if (LatestVersion != Version)
	{
		Version = LatestVersion;
		SaveConfig();
	}

	if (LogLevel == LL_WrongLevel)
	{
		LogLevel = LL_Info;
		`Log_Warn("Wrong 'LogLevel', return to default value");
		SaveConfig();
	}
	`Log_Base("LogLevel:" @ LogLevel);

	if (!Unlocker.static.IsValidTypeUnlockDLC(UnlockDLC, LogLevel))
	{
		`Log_Warn("Wrong 'UnlockDLC' value (" $ UnlockDLC $ "), return to default value (False)");
		UnlockDLC = "False";
		SaveConfig();
	}

	RemoveItems = CfgRemoveItems.static.Load(LogLevel);
	AddItems    = CfgAddItems.static.Load(LogLevel);
}

private function PostInit()
{
	local CTI_RepInfo RepInfo;

	`Log_Trace();

	if (WorldInfo == None || WorldInfo.Game == None)
	{
		SetTimer(1.0f, false, nameof(PostInit));
		return;
	}

	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None)
	{
		`Log_Fatal("Incompatible gamemode:" @ WorldInfo.Game);
		SafeDestroy();
		return;
	}

	if (KFGI.GameReplicationInfo == None)
	{
		SetTimer(1.0f, false, nameof(PostInit));
		return;
	}

	KFGRI = KFGameReplicationInfo(KFGI.GameReplicationInfo);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ KFGI.GameReplicationInfo);
		SafeDestroy();
		return;
	}

	WeapDefs = Trader.static.GenerateWeapDefList(
		KFGRI,
		RemoveItems,
		AddItems,
		CfgRemoveItems.default.bAll,
		CfgRemoveItems.default.bHRG,
		CfgRemoveItems.default.bDLC,
		bDisableItemLimitCheck,
		LogLevel);

	RemoveItems.Length = 0;
	AddItems.Length = 0;

	if (Unlocker.static.UnlockDLC(KFGI, KFGRI, UnlockDLC, WeapDefs, DLCSkinUpdateRequired, LogLevel))
	{
		`Log_Info("DLC unlocked");
	}
	`Log_Debug("DLCSkinUpdateRequired:" @ String(DLCSkinUpdateRequired.Value));

	if (bApplyPatch)
	{
		ServerPatch();
	}

	Trader.static.OverwriteTraderItems(KFGRI, WeapDefs, bApplyPatch, LogLevel);

	`Log_Info("Trader items:" @ WeapDefs.Length);

	if (bPreloadContent)
	{
		Preload(WeapDefs);
	}

	ReadyToSync = true;

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.PendingSync)
		{
			RepInfo.Replicate(WeapDefs);
		}
	}
}

private function ServerPatch()
{
	local class<KFAutoPurchaseHelper> AutoPurchaseHelper;
	local class<KFInventoryManager> InventoryManager;

	if (KFGI.KFGFxManagerClass.GetPackageName() != 'CTI')
	{
		if (Unlocker.static.CustomGFxManager(KFGI))
		{
			`Log_Warn("Custom KFGFxMoviePlayer_Manager detected:" @ String(KFGI.KFGFxManagerClass) $ ". There may be compatibility issues.");
		}

		if (KFGameInfo_VersusSurvival(KFGI) != None)
		{
			KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager_Versus';
		}
		else
		{
			KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager';
		}
	}

	if (KFGRI.TraderItems.class != class'KFGFxObject_TraderItems')
	{
		`Log_Warn("Custom TraderItems detected:" @ String(KFGRI.TraderItems.class) $ ". There may be compatibility issues.");
	}

	AutoPurchaseHelper = class<KFPlayerController>(KFGI.PlayerControllerClass).default.PurchaseHelperClass;
	if (AutoPurchaseHelper != class'KFPlayerController'.default.PurchaseHelperClass)
	{
		`Log_Warn("Custom PurchaseHelper detected:" @ String(AutoPurchaseHelper) $ ". There may be compatibility issues.");
	}

	InventoryManager = class<KFInventoryManager>(KFGI.DefaultPawnClass.default.InventoryManagerClass);
	if (InventoryManager != class'KFPawn'.default.InventoryManagerClass)
	{
		`Log_Warn("Custom InventoryManager detected:" @ String(InventoryManager) $ ". There may be compatibility issues.");
	}
}

private function Preload(const out Array<class<KFWeaponDefinition> > Content)
{
	local Array<S_PreloadContent> PreloadContent;
	local S_PreloadContent SPC;

	`Log_Trace();

	foreach Content(SPC.KFWD)
	{
		SPC.KFWC = class<KFWeapon> (DynamicLoadObject(SPC.KFWD.default.WeaponClassPath, class'Class'));
		if (SPC.KFWC != None)
		{
			if (SPC.KFWC.GetPackageName() == 'CTI' || SPC.KFWC.GetPackageName() == 'KFGameContent')
			{
				`Log_Debug("Skip preload:" @ SPC.KFWD.GetPackageName() $ "." $ SPC.KFWD);
				continue;
			}

			SPC.KFW = KFGI.Spawn(SPC.KFWC);
			if (SPC.KFW == None)
			{
				`Log_Warn("Spawn failed:" @ SPC.KFWD.default.WeaponClassPath);
				continue;
			}

			SPC.KFWA = new (SPC.KFW) class'KFW_Access';
			if (SPC.KFWA == None)
			{
				`Log_Warn("Spawn failed:" @ SPC.KFWD.default.WeaponClassPath @ "KFW_Access");
				continue;
			}

			PreloadContent.AddItem(SPC);
		}
	}

	foreach PreloadContent(SPC)
	{
		SPC.KFWA.KFW_StartLoadWeaponContent();
	}

	`Log_Info("Preloaded" @ PreloadContent.Length @ "weapon models");
}

public function NotifyLogin(Controller C)
{
	`Log_Trace();

	if (!CreateRepInfo(C))
	{
		`Log_Error("Can't create RepInfo for:" @ C);
	}
}

public function NotifyLogout(Controller C)
{
	`Log_Trace();

	DestroyRepInfo(C);
}

public function bool CreateRepInfo(Controller C)
{
	local CTI_RepInfo RepInfo;

	`Log_Trace();

	if (C == None || KFPlayerController(C) == None) return false;

	RepInfo = Spawn(class'CTI_RepInfo', C);

	if (RepInfo == None) return false;

	RepInfo.PrepareSync(Self, KFPlayerController(C), LogLevel, DLCSkinUpdateRequired.Value, bApplyPatch);

	RepInfos.AddItem(RepInfo);

	if (ReadyToSync)
	{
		RepInfo.Replicate(WeapDefs);
	}
	else
	{
		RepInfo.PendingSync = true;
	}

	return true;
}

public function bool DestroyRepInfo(Controller C)
{
	local CTI_RepInfo RepInfo;

	`Log_Trace();

	if (C == None) return false;

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner == C)
		{
			RepInfos.RemoveItem(RepInfo);
			RepInfo.SafeDestroy();
			return true;
		}
	}

	return false;
}

DefaultProperties
{
	ReadyToSync = false
}
