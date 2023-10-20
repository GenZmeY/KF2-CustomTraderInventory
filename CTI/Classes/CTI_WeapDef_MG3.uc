class CTI_WeapDef_MG3 extends KFWeapDef_MG3
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_MG3'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_LMG_MG3"
}
