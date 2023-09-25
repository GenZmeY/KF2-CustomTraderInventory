class CTI_WeapDef_Minigun extends KFWeapDef_Minigun
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Minigun'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Minigun"
}