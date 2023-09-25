class CTI_WeapDef_ChiappaRhinoDual extends KFWeapDef_ChiappaRhinoDual
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_ChiappaRhinoDual'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_ChiappaRhinoDual"
}