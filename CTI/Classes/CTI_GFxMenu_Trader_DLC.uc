class CTI_GFxMenu_Trader_DLC extends CTI_GFxMenu_Trader
	dependsOn(CTI_GFxTraderContainer_Store);

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'CTI_GFxTraderContainer_Store'))
}
