class CTI_WeapDef_GravityImploder extends KFWeapDef_GravityImploder
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_GravityImploder'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_GravityImploder"
}