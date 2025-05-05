--[[
 Appdata/Balatro/Mods - Location of current loaded mods
    - Never touch Lovely/ - Always loaded into program, and what not. 

 Appdata/Balatro/Profiles/XXX
    - Created ingame. Contains the relevent mods.
    - Maybe figure out mod configs?

 Features
    - Delete profile
    - Save profile (Mods, maybe configs)
    - Overwrite with current mods
    - List mods and ver in each profile / Differences with current
    - Export/import???


 Load:
    - Delete all non-simlink folders and files
    - Copy all files from Profile

--]]

ModProfiles = {}

ModProfiles.profiles_dir = love.filesystem.getSaveDirectory() .. "/mod_profiles"
ModProfiles.mods_dir = love.filesystem.getSaveDirectory() .. "/Mods"

ModProfiles.restart = false
ModProfiles.profiles = {}
ModProfiles.active_profile = nil

local io_thread = love.thread.newThread(SMODS.current_mod.path:match("Mods/%a*/").."io.lua")
local io_channel = love.thread.getChannel('io_channel')
io_thread:start()

ModProfiles.io_thread = {
    thread = io_thread,
    channel = io_channel,
    active = false,
}


local function getProfiles() 
    ModProfiles.profiles = {}
    local profile_count = 0
    -- profiles
    for _, v in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.profiles_dir)) do
        if v.type == "file" and not v.name == "data" then
            print('Odd file in Profiles Dir. ' .. v.name)
        end

        if v.type == "directory" then
            count = profile_count + 1
            ModProfiles.profiles[#ModProfiles.profiles+1] = {
                name = v.name,
                modtime = v.modtime,
                mods = {}
            }

            --mods
            for _, m in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.profiles_dir.."/"..v.name)) do
                if v.type == "directory" then
                    local disabled = NFS.getInfo(ModProfiles.profiles_dir.."/"..v.name.."/.lovelyignore")
                    if not disabled then
                        ModProfiles.profiles[#ModProfiles.profiles].mods[#ModProfiles.profiles[#ModProfiles.profiles].mods+1] = {
                            mod_name = m.name,
                            modtime = m.modtime
                        }
                    end
                end
            end

        end
    end
end

function recursiveCopy(old_dir, new_dir, skip_extra, depth)
    io_channel:push({
        type="copy",
        profile=old_dir,
        copy_params={
            target=new_dir,
            skip_extra=skip_extra
        }
    })
end
function recursiveDelete(profile_dir, delete_parent)
    io_channel:push({
        type="delete",
        profile=profile_dir,
        delete_params={
            delete_parent=delete_parent
        }
    })
end

local function init()
    local profiles_directory_info = NFS.getInfo(ModProfiles.profiles_dir, "directory")
    
    if profiles_directory_info then
        getProfiles()
    else
        NFS.createDirectory(ModProfiles.profiles_dir)
    end

    local data_info = NFS.getInfo(ModProfiles.profiles_dir.."/data", "file")
    if data_info then
        local data = NFS.read(ModProfiles.profiles_dir.."/data")
        ModProfiles.active_profile = data
    else
        NFS.write(ModProfiles.profiles_dir.."/data","nil")
    end
end

local function createNewProfile(name) 
    local id = name
    local profile_path = ModProfiles.profiles_dir.."/"..id
    NFS.createDirectory(profile_path)
    recursiveCopy(ModProfiles.mods_dir, profile_path, true)
end

local function loadProfile(profile)
    local profile_path = ModProfiles.profiles_dir.."/"..profile
    local profile_folder = NFS.getInfo(profile_path, "directory")

    if not profile_folder then 
        error("Modprofile doesnt exist: "..profile)
        return
    end

    ModProfiles.active_profile = profile
    print(profile)
    NFS.write(ModProfiles.profiles_dir.."/data", ModProfiles.active_profile)

    recursiveDelete(ModProfiles.mods_dir)

    recursiveCopy(profile_path, ModProfiles.mods_dir, nil)
    ModProfiles.restart = true

end
local function deleteProfile(profile)
    local profile_path = ModProfiles.profiles_dir.."/"..profile
    local profile_folder = NFS.getInfo(profile_path, "directory")

    if not profile_folder then 
        error("Modprofile doesnt exist: "..profile)
        return
    end

    if ModProfiles.active_profile == profile then 
        ModProfiles.active_profile = nil 
        NFS.write(ModProfiles.profiles_dir.."/data", ModProfiles.active_profile)
    end

    recursiveDelete(profile_path,true)
end

local old_game_update = Game.update

ModProfiles.createNewProfile = createNewProfile
ModProfiles.loadProfile = loadProfile
ModProfiles.deleteProfile = deleteProfile
ModProfiles.getProfiles = getProfiles

local previous_count = 0
function Game:update(dt)
    if previous_count ~= ModProfiles.io_thread.channel:getCount() then -- After any process ends
        previous_count = ModProfiles.io_thread.channel:getCount()

        G.FUNCS.exit_confirmation()
    end
    if ModProfiles.io_thread.channel:getCount() == 0 and ModProfiles.io_thread.active then -- Inactive
        print(ModProfiles.io_thread.channel:getCount())
        
        if ModProfiles.restart then 
            --SMODS.restart_game() 
            print("RESTST")
        end
    end

    
    
    ModProfiles.io_thread.active = ModProfiles.io_thread.channel:getCount() > 0
    --print(ModProfiles.io_thread.channel:getCount())
    old_game_update(self,dt)
end

NFS.load(SMODS.current_mod.path.."/ui.lua")()

init()