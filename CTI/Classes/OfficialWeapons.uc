class OfficialWeapons extends Object
	config(CTI);

const Trader = class'Trader';
const DefaultComment = "Auto-generated list of official weapons for your convenience, copy-paste ready";

var private config String Comment;
var private config Array<String> Item;

private delegate int ByName(String A, String B)
{
	return A > B ? -1 : 0;
}

public static function Update(bool Enabled)
{
	local Array<class<KFWeaponDefinition> > KFWeapDefs;
	local class<KFWeaponDefinition> KFWeapDef;
	
	if (!Enabled) return;

	KFWeapDefs = Trader.static.GetTraderWeapDefs();
	
	if (default.Item.Length != KFWeapDefs.Length || default.Comment != DefaultComment)
	{
		default.Comment = DefaultComment;
		default.Item.Length = 0;
		
		foreach KFWeapDefs(KFWeapDef)
		{
			default.Item.AddItem(KFWeapDef.GetPackageName() $ "." $ KFWeapDef);
		}
		
		default.Item.Sort(ByName);
		
		StaticSaveConfig();
	}
}

defaultproperties
{

}
