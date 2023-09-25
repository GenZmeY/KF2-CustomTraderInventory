class CTI_WeapDef_CompoundBow extends KFWeapDef_CompoundBow
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_CompoundBow'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Bow_CompoundBow"
}