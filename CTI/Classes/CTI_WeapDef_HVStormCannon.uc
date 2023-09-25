class CTI_WeapDef_HVStormCannon extends KFWeapDef_HVStormCannon
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_HVStormCannon'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_HVStormCannon"
}