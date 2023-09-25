class CTI_WeapDef_Shotgun_S12 extends KFWeapDef_Shotgun_S12
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Shotgun_S12'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Shotgun_S12"
}