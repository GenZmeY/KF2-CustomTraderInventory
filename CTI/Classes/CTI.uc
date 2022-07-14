class CTI extends Info
	config(CTI);

const LatestVersion = 1;

const CfgRemoveItems = class'RemoveItems';
const CfgAddItems    = class'AddItems';
const Helper         = class'Helper';

struct S_PreloadContent
{
	var class<KFWeaponDefinition> KFWD;
	var class<KFWeapon>           KFWC;
	var KFWeapon                  KFW;
	var KFW_Access                KFWA;
};

var private config int        Version;
var private config E_LogLevel LogLevel;
var private config bool       UnlockDLC;
var private config bool       bPreloadContent;

var private KFGameInfo KFGI;
var private KFGameReplicationInfo KFGRI;

var private Array<class<KFWeaponDefinition> > RemoveItems;
var private Array<class<KFWeaponDefinition> > AddItems;

var private Array<CTI_RepInfo> RepInfos;

var private bool ReadyToSync;

var private Array<S_PreloadContent> PreloadContent;

public simulated function bool SafeDestroy()
{
	`Log_Trace(`Location);
	
	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	`Log_Trace(`Location);
	
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
	`Log_Trace(`Location);
	
	if (bPendingDelete || bDeleteMe) return;
	
	Super.PostBeginPlay();
	
	PostInit();
}

private function PreInit()
{
	`Log_Trace(`Location);
	
	if (Version == `NO_CONFIG)
	{
		LogLevel = LL_Info;
		bPreloadContent = true;
		UnlockDLC = false;
		SaveConfig();
	}
	
	CfgRemoveItems.static.InitConfig(Version, LatestVersion);
	CfgAddItems.static.InitConfig(Version, LatestVersion);
	
	switch (Version)
	{
		case `NO_CONFIG:
			`Log_Info("Config created");
			
		case MaxInt:
			`Log_Info("Config updated to version"@LatestVersion);
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
	
	RemoveItems = CfgRemoveItems.static.Load(LogLevel);
	AddItems    = CfgAddItems.static.Load(LogLevel);
}

private function PostInit()
{
	local CTI_RepInfo RepInfo;
	
	`Log_Trace(`Location);
	
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
	
	// TODO:
	// replace shopContainer (KFGFxTraderContainer_Store)
	// without replacing KFGFxMoviePlayer_Manager
	// but how? 🤔
	if (UnlockDLC)
	{
		if (KFGameInfo_VersusSurvival(KFGI) != None)
		{
			if (KFGI.KFGFxManagerClass != class'CTI_GFxMoviePlayer_Manager_Versus')
			{
				if (KFGI.KFGFxManagerClass != class'KFGameInfo_VersusSurvival'.default.KFGFxManagerClass)
				{
					`Log_Warn("Found custom 'KFGFxManagerClass' (" $ KFGI.KFGFxManagerClass $ "), there may be compatibility issues");
					`Log_Warn("If you notice problems, try disabling UnlockDLC");
				}
				
				KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager_Versus';
				`Log_Info("DLC unlocked");
			}
		}
		else
		{
			if (KFGI.KFGFxManagerClass != class'CTI_GFxMoviePlayer_Manager')
			{
				if (KFGI.KFGFxManagerClass != class'KFGameInfo'.default.KFGFxManagerClass)
				{
					`Log_Warn("Found custom 'KFGFxManagerClass' (" $ KFGI.KFGFxManagerClass $ "), there may be compatibility issues");
					`Log_Warn("If you notice problems, try disabling UnlockDLC");
				}
				
				KFGI.KFGFxManagerClass = class'CTI_GFxMoviePlayer_Manager';
				`Log_Info("DLC unlocked");
			}
		}
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
	
	Helper.static.ModifyTrader(KFGRI, RemoveItems, AddItems, CfgRemoveItems.default.bAll);
	
	if (bPreloadContent)
	{
		Preload(AddItems);
	}
	
	ReadyToSync = true;
	
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.PendingSync)
		{
			RepInfo.ServerSync();
		}
	}
}

private function Preload(Array<class<KFWeaponDefinition> > Content)
{
	local S_PreloadContent SPC;
	
	foreach Content(SPC.KFWD)
	{
		SPC.KFWC = class<KFWeapon> (DynamicLoadObject(SPC.KFWD.default.WeaponClassPath, class'Class'));
		if (SPC.KFWC != None)
		{
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
}

public function NotifyLogin(Controller C)
{
	`Log_Trace(`Location);

	CreateRepInfo(C);
}

public function NotifyLogout(Controller C)
{
	`Log_Trace(`Location);

	DestroyRepInfo(C);
}

public function bool CreateRepInfo(Controller C)
{
	local CTI_RepInfo RepInfo;
	
	`Log_Trace(`Location);
	
	if (C == None) return false;
	
	RepInfo = Spawn(class'CTI_RepInfo', C);
	
	if (RepInfo == None) return false;
	
	RepInfo.PrepareSync(
		Self,
		LogLevel,
		RemoveItems,
		AddItems,
		CfgRemoveItems.default.bAll);
	
	RepInfos.AddItem(RepInfo);
	
	if (ReadyToSync)
	{
		RepInfo.ServerSync();
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
	
	`Log_Trace(`Location);
	
	if (C == None) return false;
	
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner == C)
		{
			RepInfo.SafeDestroy();
			RepInfos.RemoveItem(RepInfo);
			return true;
		}
	}
	
	return false;
}

DefaultProperties
{
	ReadyToSync = false
}