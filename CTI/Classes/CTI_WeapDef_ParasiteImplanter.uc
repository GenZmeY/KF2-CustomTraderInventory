class CTI_WeapDef_ParasiteImplanter extends KFWeapDef_ParasiteImplanter
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_ParasiteImplanter'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Rifle_ParasiteImplanter"
}