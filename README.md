# taosb
toastonrye's AE2 One Stack Blaster or TAOSB for short :)
description: This script has one main goal, to relocate items with a max stack size of 1, from the main AE2 system to a subnet.

[WARNING]
Always make a SAVE BACKUP! I have tested this script quite a bit in my world save.
I've not witnessed any issues with items going missing, but be safe!
The ME Bridge peripheral appears to not send items if the destination inventory is full.. Which is great!

[REQUIREMENTS]
1. This script requires the following mods; Applied Energistics 2(AE2), Advanced Peripherals(AP), CC:Tweaked(CC)
2. This script was made in 1.21.1 Minecraft - All The Mods 10 modpack. It's possible newer/older versions may break this script.
3. A reasonable understanding how AE2 subnets work, and how to setup the various block components in-game. 

[INSTRUCTIONS]
1. To use this script, the only settings you should need to adjust are located under the [USER SETTINGS] heading.
2. I'll need to include a picture or video to better explain how the computer and peripheral needs to be setup with the AE2 network.
3. The CC computer interfaces with essentially 3 things, the AP ME Bridge, AE2 Inverted ME Toggle Bus, and a Redstone start signal.
4. A signal is used to "kill" the AE2 subnet so it's inventory isn't re-read, transfering items that have already been moved.

[TIPS]
1. There is a query mode in [USER SETTINGS] that doesn't move any items, but if logs are turned on you can see what it would have moved.
2. Transfer all is by far the fastest, white/blacklists are much slower.
3. There is an in-game command "/advancedperipherals getHashItem" that provides a fingerprint useful for troubleshooting, see AP's docs.
   The fingerprint is a MD5 hash calculated by Advanced Peripherals; nbt tag, registry name, display name
   i.e When exporting items, the fingerprint ensures the "correct" minecraft:iron_axe is being exported.
4. Isolate parts of your main AE2 system that you don't need sorted, like a drawer/storage bus system or other subnet.
   Searching is faster with less total items. My test AE2 system had 1500 items and it took ~10 seconds.
   You can automate isolating parts of your AE2 network with toggle buses and redstone that ties into this script. 

[KNOWN ISSUES OR BUGS]
1. filtering - some mods like Ars Nouveau use 'minecraft:potion' so the white/black list filtering doesn't always work.
2. probably should add some sort of AE2 network offline situation?
