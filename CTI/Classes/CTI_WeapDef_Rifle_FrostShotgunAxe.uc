class CTI_WeapDef_Rifle_FrostShotgunAxe extends KFWeapDef_Rifle_FrostShotgunAxe
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Rifle_FrostShotgunAxe'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Rifle_FrostShotgunAxe"
}