class CTI_WeapDef_FAMAS extends KFWeapDef_FAMAS
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_FAMAS'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_AssaultRifle_FAMAS"
}