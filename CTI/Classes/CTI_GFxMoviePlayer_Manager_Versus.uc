class CTI_GFxMoviePlayer_Manager_Versus extends KFGFxMoviePlayer_Manager_Versus
	dependsOn(CTI_GFxMenu_Trader);

defaultproperties
{
	WidgetBindings.Remove((WidgetName="traderMenu",WidgetClass=class'KFGFxMenu_Trader'))
	WidgetBindings.Add((WidgetName="traderMenu",WidgetClass=class'CTI_GFxMenu_Trader'))
}
