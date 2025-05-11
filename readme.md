### Mod Profiles
Allows the easy switching of many mods! Even SMODs versions.


## How to create a Mod Profile?

There are 2 ways. 

#### 1) Ingame.

 - Clear out your normal Mods Folder (Appdata/Balatro/Mods/)
 - Copy all of the mods that you want the new Profile to contain
 - Restart your game (Load the mods)  --Actually might not be required lmao
 - Open the Mods>Profiles menu, and click "New" in the top left
 - Give the profile a name, and hit "Create".
 - Done! It will take a bit of time, depending on how many mods you have. (More than 10 can take +15 seconds)


#### 2) Manually.

 - Go to the Profiles Folder (Appdata/Balatro/mod_profiles)
 - Create a new folder with a unique name
 - Put the desired mods within the folder.
 - Done!



## For Modpack Creators

Theres a simple way to get a nice UI in the Profiles menu. 

To make your modpack support Mod Profiles, all you have to do is add a file named `profile.lua` in the root folder of the modpack.<br>
It should look like `ModPack.zip/profile.lua`. All mods should be in the same folder

Below is an example of the `profile.lua` file.
```lua
return {
    name = "Coonie's Neo",
    main_colour = "00cca3",
    secondary_colour = nil, -- Sets the colour of profile buttons.
    description = "A curated collection of Balatro mods made by many wonderful members of the community. Specially curated towards a vannilia+ game experience where things can get nuts,",
    author = {"GayCoonie"},
    url = "https://github.com/GayCoonie/Coonies-Mod-Pack-Neo",
    version = "v12",
}
```