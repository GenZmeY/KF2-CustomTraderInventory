class CTIMut extends KFMutator;

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

public function AddMutator(Mutator Mut)
{
	if (Mut == Self) return;

	if (Mut.Class == Class)
		Mut.Destroy();
	else
		Super.AddMutator(Mut);
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

}