# Changelog

## v1.8.2 (2024-02-25)
- fixed InvManager initialization after player death

## v1.8.1 (2024-01-08)
- fixed single player mode

## v1.8.0 (2024-01-07)
- added a patch for: KFAutoPurchaseHelper, KFInventoryManager, KFGFxMenu_Trader, KFGFxObject_TraderItems
- added the ability for players to sell weapons that excluded from trader inventory
- fixed bugs that occurred when a trader had more than 256 items for sale
- added a short alias for the mutator: CTI.Mut (CTI.CTIMut is still available for use)
- added advice for players when they have problems with GRI initialization

## v1.7.3 (2023-10-21)
- fixed 9mm/HRG93R filter

## v1.7.2 (2023-10-21)
- updated to KF2 v1147
- unlocked MG3
- DLC clones now removed along with their originals from [CTI.RemoveItems]
- added forced GRI initialization when possible
- forced update of skins for DLC clones
- minor optimizations

## v1.7.1 (2023-10-05)
- replaced DLCs now have the same skin as the originals

## v1.7.0 (2023-09-19)
- item synchronization has been significantly accelerated
- added a check for the limit of items (256) in the trader inventory
- added an option to disable the above limit in the config
- fixed game crash caused by preloading DLC weapons
- fixed TF2 Sentry preload
- GRI waiting limit increased to 30 seconds

## v1.6.2 (2023-09-11)
- fixed weapon replacements

## v1.6.1 (2023-06-29)
- add waiting GRI limit
- unlock S12
- added mutator group (Mutator::GroupNames)

## v1.6.0 (2022-12-07)
- update to kf2 v1137
- remove DLC option
- remove HRG option
- unlock HVStormCannon and ZedMKIII

## v1.5.2 (2022-10-13)
- unlock G36C and Scythe

## v1.5.1 (2022-09-13)
- fix notify login/logout order
- fix false "error": "Cant destroy RepInfo"
- update build tools

## v1.5.0 (2022-08-30)
- change some logs
- add russian localization
- slightly changed sync HUD

## v1.4.0 (2022-07-18)
- added WeaponClass check at config loading stage
- added DLC unlock without replacing KFGFxMoviePlayer_Manager
- redesigned UnlockDLC - now it is flexibly configured
- update logger and some messages in the log
- added parameter bOfficialWeaponsList allowing you
- optimized weapon preload: official weapon models are skipped now

## v1.3.2 (2022-07-13)
- fix premature deletion of CTI_RepInfo

## v1.3.1 (2022-07-11)
- fix trader when client didn't get GameReplicationInfo
- preload content optimizations

## v1.3.0 (2022-07-10)
- preload content (and now it actually works)

## v1.2.2 (2022-07-08)
- completely removed Force Preload (due to side effects)

## v1.2.1 (2022-07-08)
- fix preload notification

## v1.2.0 (2022-07-08)
- Reworked Preload content (again and finally)

## v1.1.0 (2022-07-07)
- add versus mode support
- fix preload content

## v1.0.0 (2022-07-05)
- first version
