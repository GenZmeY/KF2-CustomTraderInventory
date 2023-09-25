class CTI_WeapDef_ThermiteBore extends KFWeapDef_ThermiteBore
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_ThermiteBore'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_RocketLauncher_ThermiteBore"
}