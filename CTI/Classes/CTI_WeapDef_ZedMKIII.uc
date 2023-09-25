class CTI_WeapDef_ZedMKIII extends KFWeapDef_ZedMKIII
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_ZedMKIII'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_ZedMKIII"
}