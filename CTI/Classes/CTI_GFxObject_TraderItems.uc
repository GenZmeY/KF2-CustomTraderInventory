class CTI_GFxObject_TraderItems extends KFGFxObject_TraderItems;

var() Array<STraderItem> AllItems;

public function bool CTI_GetItemIndicesFromArche(out int ItemIndex, name WeaponClassName)
{
	local int Index;

	Index = AllItems.Find('ClassName', WeaponClassName);

	if (Index == INDEX_NONE) return false;

	ItemIndex = Index;

	return true;
}

DefaultProperties
{

}