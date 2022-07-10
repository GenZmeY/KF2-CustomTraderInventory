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
	local CTI_RepInfo RepLink;
	
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
					`Log_Warn("If you notice problems, try disabling DLC unlock");
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
					`Log_Warn("If you notice problems, try disabling DLC unlock");
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
		InitPreload(AddItems);
	}
	
	ReadyToSync = true;
	
	foreach RepInfos(RepLink)
	{
		if (RepLink.PendingSync)
		{
			RepLink.ServerSync();
		}
	}
}

private function InitPreload(Array<class<KFWeaponDefinition> > Content)
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
	
	`Log_Debug("PreloadContent:" @ PreloadContent.Length);
}

public function StartPreload(class<KFWeaponDefinition> KFWeapDef)
{
	local S_PreloadContent SPC;
	
	foreach PreloadContent(SPC)
	{
		if (SPC.KFWD == KFWeapDef)
		{
			SPC.KFWA.KFW_StartLoadWeaponContent();
			`Log_Debug("Preload:" @ SPC.KFW);
			break;
		}
	}
}

public function NotifyLogin(Controller C)
{
	`Log_Trace(`Location);

	CreateRepLink(C);
}

public function NotifyLogout(Controller C)
{
	`Log_Trace(`Location);

	DestroyRepLink(C);
}

public function bool CreateRepLink(Controller C)
{
	local CTI_RepInfo RepLink;
	
	`Log_Trace(`Location);
	
	if (C == None) return false;
	
	RepLink = Spawn(class'CTI_RepInfo', C);
	
	if (RepLink == None) return false;
	
	RepLink.PrepareSync(
		Self,
		LogLevel,
		RemoveItems,
		AddItems,
		CfgRemoveItems.default.bAll,
		bPreloadContent);
	
	RepInfos.AddItem(RepLink);
	
	if (ReadyToSync)
	{
		RepLink.ServerSync();
	}
	else
	{
		RepLink.PendingSync = true;
	}
	
	return true;
}

public function bool DestroyRepLink(Controller C)
{
	local CTI_RepInfo RepLink;
	
	`Log_Trace(`Location);
	
	if (C == None) return false;
	
	foreach RepInfos(RepLink)
	{
		if (RepLink.Owner == C)
		{
			RepLink.SafeDestroy();
			RepInfos.RemoveItem(RepLink);
			return true;
		}
	}
	
	return false;
}

DefaultProperties
{
	ReadyToSync = false
}