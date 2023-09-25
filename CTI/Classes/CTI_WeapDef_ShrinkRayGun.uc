class CTI_WeapDef_ShrinkRayGun extends KFWeapDef_ShrinkRayGun
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_ShrinkRayGun'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_ShrinkRayGun"
}