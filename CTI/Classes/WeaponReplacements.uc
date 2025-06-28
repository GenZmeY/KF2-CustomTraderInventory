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

class WeaponReplacements extends Object;

struct SWeapReplace
{
	var const class<KFWeaponDefinition> WeapDef;
	var const class<KFWeaponDefinition> WeapDefParent;
	var const class<KFWeapon>           Weap;
	var const class<KFWeapon>           WeapParent;
};

var public const Array<SWeapReplace> DLC;

defaultproperties
{
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_AutoTurret',
		WeapDefParent=class'KFWeapDef_AutoTurret',
		Weap=class'CTI_Weap_AutoTurret',
		WeapParent=class'KFWeap_AutoTurret'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_BladedPistol',
		WeapDefParent=class'KFWeapDef_BladedPistol',
		Weap=class'CTI_Weap_Pistol_Bladed',
		WeapParent=class'KFWeap_Pistol_Bladed'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Blunderbuss',
		WeapDefParent=class'KFWeapDef_Blunderbuss',
		Weap=class'CTI_Weap_Pistol_Blunderbuss',
		WeapParent=class'KFWeap_Pistol_Blunderbuss'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ChainBat',
		WeapDefParent=class'KFWeapDef_ChainBat',
		Weap=class'CTI_Weap_Blunt_ChainBat',
		WeapParent=class'KFWeap_Blunt_ChainBat'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ChiappaRhino',
		WeapDefParent=class'KFWeapDef_ChiappaRhino',
		Weap=class'CTI_Weap_Pistol_ChiappaRhino',
		WeapParent=class'KFWeap_Pistol_ChiappaRhino'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ChiappaRhinoDual',
		WeapDefParent=class'KFWeapDef_ChiappaRhinoDual',
		Weap=class'CTI_Weap_Pistol_ChiappaRhinoDual',
		WeapParent=class'KFWeap_Pistol_ChiappaRhinoDual'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_CompoundBow',
		WeapDefParent=class'KFWeapDef_CompoundBow',
		Weap=class'CTI_Weap_Bow_CompoundBow',
		WeapParent=class'KFWeap_Bow_CompoundBow'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Doshinegun',
		WeapDefParent=class'KFWeapDef_Doshinegun',
		Weap=class'CTI_Weap_AssaultRifle_Doshinegun',
		WeapParent=class'KFWeap_AssaultRifle_Doshinegun'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_DualBladed',
		WeapDefParent=class'KFWeapDef_DualBladed',
		Weap=class'CTI_Weap_Pistol_DualBladed',
		WeapParent=class'KFWeap_Pistol_DualBladed'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_FAMAS',
		WeapDefParent=class'KFWeapDef_FAMAS',
		Weap=class'CTI_Weap_AssaultRifle_FAMAS',
		WeapParent=class'KFWeap_AssaultRifle_FAMAS'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_G18',
		WeapDefParent=class'KFWeapDef_G18',
		Weap=class'CTI_Weap_SMG_G18',
		WeapParent=class'KFWeap_SMG_G18'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_G36C',
		WeapDefParent=class'KFWeapDef_G36C',
		Weap=class'CTI_Weap_AssaultRifle_G36C',
		WeapParent=class'KFWeap_AssaultRifle_G36C'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_GravityImploder',
		WeapDefParent=class'KFWeapDef_GravityImploder',
		Weap=class'CTI_Weap_GravityImploder',
		WeapParent=class'KFWeap_GravityImploder'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_HVStormCannon',
		WeapDefParent=class'KFWeapDef_HVStormCannon',
		Weap=class'CTI_Weap_HVStormCannon',
		WeapParent=class'KFWeap_HVStormCannon'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_IonThruster',
		WeapDefParent=class'KFWeapDef_IonThruster',
		Weap=class'CTI_Weap_Edged_IonThruster',
		WeapParent=class'KFWeap_Edged_IonThruster'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_MG3',
		WeapDefParent=class'KFWeapDef_MG3',
		Weap=class'CTI_Weap_LMG_MG3',
		WeapParent=class'KFWeap_LMG_MG3'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Mine_Reconstructor',
		WeapDefParent=class'KFWeapDef_Mine_Reconstructor',
		Weap=class'CTI_Weap_Mine_Reconstructor',
		WeapParent=class'KFWeap_Mine_Reconstructor'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Minigun',
		WeapDefParent=class'KFWeapDef_Minigun',
		Weap=class'CTI_Weap_Minigun',
		WeapParent=class'KFWeap_Minigun'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_MosinNagant',
		WeapDefParent=class'KFWeapDef_MosinNagant',
		Weap=class'CTI_Weap_Rifle_MosinNagant',
		WeapParent=class'KFWeap_Rifle_MosinNagant'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ParasiteImplanter',
		WeapDefParent=class'KFWeapDef_ParasiteImplanter',
		Weap=class'CTI_Weap_Rifle_ParasiteImplanter',
		WeapParent=class'KFWeap_Rifle_ParasiteImplanter'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Pistol_DualG18',
		WeapDefParent=class'KFWeapDef_Pistol_DualG18',
		Weap=class'CTI_Weap_Pistol_DualG18',
		WeapParent=class'KFWeap_Pistol_DualG18'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Pistol_G18C',
		WeapDefParent=class'KFWeapDef_Pistol_G18C',
		Weap=class'CTI_Weap_Pistol_G18C',
		WeapParent=class'KFWeap_Pistol_G18C'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Rifle_FrostShotgunAxe',
		WeapDefParent=class'KFWeapDef_Rifle_FrostShotgunAxe',
		Weap=class'CTI_Weap_Rifle_FrostShotgunAxe',
		WeapParent=class'KFWeap_Rifle_FrostShotgunAxe'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Scythe',
		WeapDefParent=class'KFWeapDef_Scythe',
		Weap=class'CTI_Weap_Edged_Scythe',
		WeapParent=class'KFWeap_Edged_Scythe'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Shotgun_S12',
		WeapDefParent=class'KFWeapDef_Shotgun_S12',
		Weap=class'CTI_Weap_Shotgun_S12',
		WeapParent=class'KFWeap_Shotgun_S12'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ShrinkRayGun',
		WeapDefParent=class'KFWeapDef_ShrinkRayGun',
		Weap=class'CTI_Weap_ShrinkRayGun',
		WeapParent=class'KFWeap_ShrinkRayGun'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ThermiteBore',
		WeapDefParent=class'KFWeapDef_ThermiteBore',
		Weap=class'CTI_Weap_RocketLauncher_ThermiteBore',
		WeapParent=class'KFWeap_RocketLauncher_ThermiteBore'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_ZedMKIII',
		WeapDefParent=class'KFWeapDef_ZedMKIII',
		Weap=class'CTI_Weap_ZedMKIII',
		WeapParent=class'KFWeap_ZedMKIII'
	)})
	DLC.Add({(
		WeapDef=class'CTI_WeapDef_Zweihander',
		WeapDefParent=class'KFWeapDef_Zweihander',
		Weap=class'CTI_Weap_Edged_Zweihander',
		WeapParent=class'KFWeap_Edged_Zweihander'
	)})
}
