class CTI_WeapDef_Pistol_DualG18 extends KFWeapDef_Pistol_DualG18
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Pistol_DualG18'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_DualG18"
}