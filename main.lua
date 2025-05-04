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
    - Copy all files from Global
    - Copy all files from Profile -- Skipping any that are from Global

--]]

ModProfiles = {}

ModProfiles.profiles_dir = love.filesystem.getSaveDirectory() .. "/mod_profiles"
ModProfiles.mods_dir = love.filesystem.getSaveDirectory() .. "/Mods"

ModProfiles.global_files = {}
ModProfiles.profiles = {}
ModProfiles.active_profile = nil

local function safeFunc(func, path, data)
    if string.find(path,ModProfiles.profiles_dir) == 1 or string.find(path,ModProfiles.mods_dir) == 1 then
        return func(path,data)
    else
        error("Path outside of allowed folder: " ..path)
    end
end
local function getProfiles() 
    ModProfiles.profiles = {}
    local profile_count = 0
    -- profiles
    for _, v in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.profiles_dir)) do
        if v.type == "file" and not v.name == "data" then
            print('Odd file in Profiles Dir. ' .. v.name)
        end

        if v.type == "directory" and v.name ~= "Global" then
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
    depth = depth or 7
    for k, v in ipairs(NFS.getDirectoryItemsInfo(old_dir)) do
        if (ModProfiles.global_files and not ModProfiles.global_files[v.name]) or (not ModProfiles.global_files) then 
            if v.type == "directory" then
                NFS.createDirectory(new_dir.."/"..v.name)
                if depth > 0 then 
                    recursiveCopy(old_dir.."/"..v.name, new_dir.."/"..v.name, depth-1) 
                end
            elseif not (skip_extra and (v.type == "symlink" or (v.name == "lovely" and depth == 7))) then
                local file = NFS.read(old_dir.."/"..v.name)
                NFS.write(new_dir.."/"..v.name, file)
            end
        end
        
    end
end
function recursiveDelete(profile_dir, depth)
    depth = depth or 7

    failed = 0
    succeeded = 0
    
    for k, v in ipairs(NFS.getDirectoryItemsInfo(profile_dir)) do
        if v.type ~= "symlink" then
            if v.type == "directory" then
                if depth > 0 then  
                    recursiveDelete(profile_dir.."/"..v.name, depth-1) 
                    
                    local success = NFS.remove(profile_dir.."/"..v.name)
                    if success then succeeded = succeeded + 1 else failed = failed + 1 end
                end
            else
                local success = NFS.remove(profile_dir.."/"..v.name)
                if success then succeeded = succeeded + 1 else failed = failed + 1 end
            end
        end
    end
    return {failed = failed, succeeded = succeeded}
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

local function getGlobalMods()
    local globals = {}
    for k, v in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.profiles_dir.."/Global")) do
        if v.type == "directory" then
            globals[v.name] = true
        end
    end
    return globals
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

    ModProfiles.global_files = getGlobalMods()

    recursiveCopy(ModProfiles.profiles_dir.."/Global/", ModProfiles.mods_dir)

    recursiveCopy(profile_path, ModProfiles.mods_dir, nil)


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

    recursiveDelete(profile_path)
    NFS.remove(profile_path)
end


ModProfiles.createNewProfile = createNewProfile
ModProfiles.loadProfile = loadProfile
ModProfiles.deleteProfile = deleteProfile
ModProfiles.getProfiles = getProfiles
ModProfiles.safeFunc = safeFunc
ModProfiles.getGlobalMods = getGlobalMods

NFS.load(SMODS.current_mod.path.."/ui.lua")()

init()