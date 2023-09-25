class CTI_WeapDef_Blunderbuss extends KFWeapDef_Blunderbuss
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Blunderbuss'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_Blunderbuss"
}