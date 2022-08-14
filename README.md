# Custom Trader Inventory

[![Steam Workshop](https://img.shields.io/static/v1?message=workshop&logo=steam&labelColor=gray&color=blue&logoColor=white&label=steam%20)](https://steamcommunity.com/sharedfiles/filedetails/?id=2830826239)
[![Steam Downloads](https://img.shields.io/steam/downloads/2830826239)](https://steamcommunity.com/sharedfiles/filedetails/?id=2830826239)
[![Steam Favorites](https://img.shields.io/steam/favorites/2830826239)](https://steamcommunity.com/sharedfiles/filedetails/?id=2830826239)
[![Steam Update Date](https://img.shields.io/steam/update-date/2830826239)](https://steamcommunity.com/sharedfiles/filedetails/?id=2830826239)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/GenZmeY/KF2-CustomTraderInventory)](https://github.com/GenZmeY/KF2-CustomTraderInventory/tags)
[![GitHub](https://img.shields.io/github/license/GenZmeY/KF2-CustomTraderInventory)](LICENSE)

# Description
Add/Remove Items in the Trader's Inventory  

# Features
- remove/add items to trader;
- can preload weapon models (no lags when buying weapons);
- unlock DLC weapons;
- correct items sorting (by price);
- don't have to worry about adding new guns after each Tripware update.

# Usage & Setup
[See steam workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=2830826239)

# Build
**Note:** If you want to build/test/brew/publish a mutator without git-bash and/or scripts, follow [these instructions](https://tripwireinteractive.atlassian.net/wiki/spaces/KF2SW/pages/26247172/KF2+Code+Modding+How-to) instead of what is described here.
1. Install [Killing Floor 2](https://store.steampowered.com/app/232090/Killing_Floor_2/), Killing Floor 2 - SDK and [git for windows](https://git-scm.com/download/win);
2. open git-bash and go to any folder where you want to store sources:  
`cd <ANY_FOLDER_YOU_WANT>`  
3. Clone this repository and go to the source folder:  
`git clone https://github.com/GenZmeY/KF2-CustomTraderInventory && cd KF2-CustomTraderInventory`
4. Download dependencies:  
`git submodule init && git submodule update`  
5. Compile:  
`./tools/builder -c`  
5. The compiled files will be here:  
`C:\Users\<USERNAME>\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script\`

# Testing
Open git-bash in the source folder and run command:  
`./tools/builder -t`  
(or `./tools/builder -ct` if you haven't compiled the mutator yet)  

A local single-user test will be launched with parameters from `builder.cfg` (edit this file if you want to test mutator with different parameters).

# Bug reports
If you find a bug, go to the [issue page](https://github.com/GenZmeY/KF2-CustomTraderInventory/issues) and check if there is a description of your bug. If not, create a new issue.  
Describe what the bug looks like and how reproduce it.  

# License
[GNU GPLv3](LICENSE)  
