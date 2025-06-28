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

class _Logger extends Object
	abstract;

enum E_LogLevel
{
	LL_WrongLevel,
	LL_None,
	LL_Fatal,
	LL_Error,
	LL_Warning,
	LL_Info,
	LL_Debug,
	LL_Trace,
	LL_All
};

defaultproperties
{

}
