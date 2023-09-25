class CTI_WeapDef_MosinNagant extends KFWeapDef_MosinNagant
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_MosinNagant'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Rifle_MosinNagant"
}