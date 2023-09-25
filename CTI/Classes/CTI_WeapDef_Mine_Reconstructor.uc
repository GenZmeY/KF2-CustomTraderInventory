class CTI_WeapDef_Mine_Reconstructor extends KFWeapDef_Mine_Reconstructor
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Mine_Reconstructor'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Mine_Reconstructor"
}