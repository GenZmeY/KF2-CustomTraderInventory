class CTI_WeapDef_BladedPistol extends KFWeapDef_BladedPistol
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_BladedPistol'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_Bladed"
}