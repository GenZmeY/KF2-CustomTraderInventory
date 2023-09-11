class CTI_WeapDef_Rifle_FrostShotgunAxe extends KFWeapDef_Rifle_FrostShotgunAxe
	abstract;

static function String GetItemLocalization(String KeyName)
{
	local Array<String> Strings;
	ParseStringIntoArray(class'KFGame.KFWeapDef_Rifle_FrostShotgunAxe'.default.WeaponClassPath, Strings, ".", true);
	return Localize(Strings[1], KeyName, Strings[0]);
}

defaultproperties
{
	SharedUnlockId  = SCU_None
	WeaponClassPath = "CTI.CTI_Weap_Rifle_FrostShotgunAxe"
}