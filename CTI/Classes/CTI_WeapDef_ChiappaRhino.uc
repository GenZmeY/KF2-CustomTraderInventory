class CTI_WeapDef_ChiappaRhino extends KFWeapDef_ChiappaRhino
	abstract;

static function String GetItemLocalization(String KeyName)
{
	return class'KFGame.KFWeapDef_ChiappaRhino'.static.GetItemLocalization(KeyName);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_ChiappaRhino"
}