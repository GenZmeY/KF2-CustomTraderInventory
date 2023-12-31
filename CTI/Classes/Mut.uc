class Mut extends KFMutator;

var private CTI CTI;

public simulated function bool SafeDestroy()
{
	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	Super.PreBeginPlay();

	if (WorldInfo.NetMode == NM_Client) return;

	foreach WorldInfo.DynamicActors(class'CTI', CTI)
	{
		break;
	}

	if (CTI == None)
	{
		CTI = WorldInfo.Spawn(class'CTI');
	}

	if (CTI == None)
	{
		`Log_Base("FATAL: Can't Spawn 'CTI'");
		SafeDestroy();
	}
}

public function AddMutator(Mutator M)
{
	if (M == Self) return;

	if (M.Class == Class)
		Mut(M).SafeDestroy();
	else
		Super.AddMutator(M);
}

public function NotifyLogin(Controller C)
{
	CTI.NotifyLogin(C);

	Super.NotifyLogin(C);
}

public function NotifyLogout(Controller C)
{
	CTI.NotifyLogout(C);

	Super.NotifyLogout(C);
}

DefaultProperties
{
	GroupNames.Add("TraderItems")
}