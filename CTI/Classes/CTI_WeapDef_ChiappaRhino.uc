class CTI_WeapDef_ChiappaRhino extends KFWeapDef_ChiappaRhino
	abstract;

static function String GetItemLocalization(String KeyName)
{
	local Array<String> Strings;
	ParseStringIntoArray(class'KFGame.KFWeapDef_ChiappaRhino'.default.WeaponClassPath, Strings, ".", true);
	return Localize(Strings[1], KeyName, Strings[0]);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Pistol_ChiappaRhino"
}