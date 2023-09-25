class CTI_WeapDef_Pistol_G18C extends KFWeapDef_Pistol_G18C
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Pistol_G18C'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_G18C"
}