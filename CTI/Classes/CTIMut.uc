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
		`Log_Base("Found 'CTI'");
		break;
	}
	
	if (CTI == None)
	{
		`Log_Base("Spawn 'CTI'");
		CTI = WorldInfo.Spawn(class'CTI');
	}
	
	if (CTI == None)
	{
		`Log_Base("Can't Spawn 'CTI', Destroy...");
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
	Super.NotifyLogin(C);
	
	CTI.NotifyLogin(C);
}

public function NotifyLogout(Controller C)
{
	Super.NotifyLogout(C);
	
	CTI.NotifyLogout(C);
}

DefaultProperties
{

}