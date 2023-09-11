class CTI_WeapDef_Shotgun_S12 extends KFWeapDef_Shotgun_S12
	abstract;

static function String GetItemLocalization(String KeyName)
{
	local Array<String> Strings;
	ParseStringIntoArray(class'KFGame.KFWeapDef_Shotgun_S12'.default.WeaponClassPath, Strings, ".", true);
	return Localize(Strings[1], KeyName, Strings[0]);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Shotgun_S12"
}