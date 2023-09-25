class CTI_WeapDef_Doshinegun extends KFWeapDef_Doshinegun
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_Doshinegun'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_AssaultRifle_Doshinegun"
}