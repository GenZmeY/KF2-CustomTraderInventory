// This file is part of Custom Trader Inventory.
// Custom Trader Inventory - a mutator for Killing Floor 2.
//
// Copyright (C) 2022-2024 GenZmeY (mailto: genzmey@gmail.com)
//
// Custom Trader Inventory is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Custom Trader Inventory is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with Custom Trader Inventory. If not, see <https://www.gnu.org/licenses/>.

class CTI_LocalMessage extends Object
	abstract;

var const             String SyncItemsDefault;
var private localized String SyncItems;

var const             String WaitingGRIDefault;
var private localized String WaitingGRI;

var const             String IncompatibleGRIDefault;
var private localized String IncompatibleGRI;

var const             String IncompatibleGRIWarningDefault;
var private localized String IncompatibleGRIWarning;

var const             String NoneGRIDefault;
var private localized String NoneGRI;

var const             String NoneGRIWarningDefault;
var private localized String NoneGRIWarning;

var const             String SecondsShortDefault;
var private localized String SecondsShort;

var const             String PleaseWaitDefault;
var private localized String PleaseWait;

enum E_CTI_LocalMessageType
{
	CTI_SyncItems,
	CTI_WaitingGRI,
	CTI_IncompatibleGRI,
	CTI_IncompatibleGRIWarning,
	CTI_NoneGRI,
	CTI_NoneGRIWarning,
	CTI_SecondsShort,
	CTI_PleaseWait
};

public static function String GetLocalizedString(
	E_LogLevel LogLevel,
	E_CTI_LocalMessageType LMT,
	optional String String1,
	optional String String2,
	optional String String3)
{
	`Log_TraceStatic();

	switch (LMT)
	{
		case CTI_SyncItems:
			return (default.SyncItems != "" ? default.SyncItems : default.SyncItemsDefault);

		case CTI_WaitingGRI:
			return (default.WaitingGRI != "" ? default.WaitingGRI : default.WaitingGRIDefault);

		case CTI_IncompatibleGRI:
			return (default.IncompatibleGRI != "" ? default.IncompatibleGRI : default.IncompatibleGRIDefault) @ String1;

		case CTI_IncompatibleGRIWarning:
			return (default.IncompatibleGRIWarning != "" ? default.IncompatibleGRIWarning : default.IncompatibleGRIWarningDefault);

		case CTI_NoneGRI:
			return (default.NoneGRI != "" ? default.NoneGRI : default.NoneGRIDefault);

		case CTI_NoneGRIWarning:
			return (default.NoneGRIWarning != "" ? default.NoneGRIWarning : default.NoneGRIWarningDefault);

		case CTI_SecondsShort:
			return (default.SecondsShort != "" ? default.SecondsShort : default.SecondsShortDefault);

		case CTI_PleaseWait:
			return (default.PleaseWait != "" ? default.PleaseWait : default.PleaseWaitDefault);
	}

	return "";
}

defaultproperties
{
	SyncItemsDefault              = "Sync items:"
	WaitingGRIDefault             = "Waiting GRI..."
	IncompatibleGRIDefault        = "Incompatible GRI:"
	IncompatibleGRIWarningDefault = "You can enter the game, but the trader may not work correctly.";
	NoneGRIDefault                = "GRI is not initialized!"
	NoneGRIWarningDefault         = "It is recommended to reconnect. If you enter the game right now, the trader may not work correctly.";
	SecondsShortDefault           = "s"
	PleaseWaitDefault             = "Please wait"
}