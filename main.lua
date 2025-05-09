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
ModProfiles.mod_folder = SMODS.current_mod.path:match("Mods/([%p%w%s]*)/")
local io_thread = love.thread.newThread("Mods/"..ModProfiles.mod_folder.."/io.lua")
local io_channel = love.thread.getChannel('io_channel')
local io_out = love.thread.getChannel('io_out')
io_thread:start(ModProfiles.mod_folder)
ModProfiles.io_thread = {
    thread = io_thread,
    channel = io_channel,
    out = io_out,
    active = false,
    proc_count = 0, -- again.
}

SMODS.Gradient {
    key = "active_profile",
    colours = {darken(G.C.RARITY[4],.4), G.C.UI.TEXT_INACTIVE}
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
                mods = {},
                has_smods=false
            }

            --mods

            for _, m in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.profiles_dir.."/"..v.name)) do
                if v.type == "directory" then
                    local disabled = NFS.getInfo(ModProfiles.profiles_dir.."/"..v.name.."/"..m.name.."/.lovelyignore")
                    if not disabled then
                        ModProfiles.profiles[#ModProfiles.profiles].mods[#ModProfiles.profiles[#ModProfiles.profiles].mods+1] = {
                            mod_name = m.name,
                            modtime = m.modtime
                        }

                        local ok, chunk, err = pcall(NFS.load, ModProfiles.profiles_dir.."/"..v.name.."/"..m.name.."/version.lua")
                        if ok and chunk then
                            local version = chunk()
                            ModProfiles.profiles[#ModProfiles.profiles].has_smods = version:match("%d%.%d%.%d~BETA%-%d%d%d%d%a%-STEAMODDED") and 1 or version:match("%d%.%d%.%d~ALPHA%-%d%d%d%d%a%-STEAMODDED") and 2 or 0
                        end
                    end
                end
            end

        end
    end
end

function recursiveCopy(old_dir, new_dir, depth)
    local id = io_channel:push({
        type="copy",
        profile=old_dir,
        copy_params={
            target=new_dir,
        }
    })
    ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count + 1
end
function recursiveDelete(profile_dir, delete_parent, depth)
    local id = io_channel:push({
        type="delete",
        profile=profile_dir,
        delete_params={
            delete_parent=delete_parent
        }
    })
    ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count + 1
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
        if ModProfiles.active_profile == "nil" then ModProfiles.active_profile = nil end
    else
        NFS.write(ModProfiles.profiles_dir.."/data","nil")
    end

    sendInfoMessage("Active Profile: " .. (ModProfiles.active_profile or "None"), "ModProfiles-Init")
end

local function saveActiveProfileToFile()
    NFS.write(ModProfiles.profiles_dir.."/data", tostring(ModProfiles.active_profile))
end


local function createNewProfile(name) 
    local id = name
    local profile_path = ModProfiles.profiles_dir.."/"..id
    NFS.createDirectory(profile_path)
    recursiveCopy(ModProfiles.mods_dir, profile_path)
    if not ModProfiles.active_profile then ModProfiles.active_profile = name end
    saveActiveProfileToFile()
end

local function loadProfile(profile)
    local profile_path = ModProfiles.profiles_dir.."/"..profile
    local profile_folder = NFS.getInfo(profile_path, "directory")

    if not profile_folder then 
        error("Modprofile doesnt exist: "..profile)
        return
    end

    ModProfiles.active_profile = profile
    print("loadl " .. profile)
    saveActiveProfileToFile()

    recursiveDelete(ModProfiles.mods_dir)

    recursiveCopy(profile_path, ModProfiles.mods_dir)
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
        saveActiveProfileToFile()
    end

    recursiveDelete(profile_path,true)
end


ModProfiles.createNewProfile = createNewProfile
ModProfiles.loadProfile = loadProfile
ModProfiles.deleteProfile = deleteProfile
ModProfiles.getProfiles = getProfiles

local old_game_update = Game.update
function Game:update(dt)
    if ModProfiles.io_thread.thread:getError() then
        error(ModProfiles.io_thread.thread:getError())
    end

    if type(ModProfiles.io_thread.out:peek())  ~= "nil" then 
        -- Code to run at 'End of task'. Out will always recieve a message at end of task, unless fatal error.
        local ret = ModProfiles.io_thread.out:pop();
        ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count-1
        ModProfiles.io_thread.active = ModProfiles.io_thread.proc_count ~= 0
        if type(ret) == "string" then
            print(ret .. " " .. tostring(ModProfiles.io_thread.active)); 
        end
            print("type " .. type(ret)); 
            -- All tasks done, run ending codes
        if type(ret) == "string" then
            if not ModProfiles.io_thread.active then
                G.FUNCS.exit_confirmation()
                play_sound('holo1', 1.5, 1)
                if ModProfiles.restart then SMODS.restart_game() end
            end
        elseif type(ret) == "table" then
            sendWarnMessage("Loading fucked up chat", "ModProfiles-IO_Thread")
            love.system.setClipboardText(tprint(ret))
            G.FUNCS.overlay_menu({
                definition = create_UIBox_generic_options({
                    back_func = "exit_confirmation",
                    no_back = true,
                    contents = {
                        {
                            n = G.UIT.C,
                            config = { padding = 0, align = "tm"},
                            nodes = {
                                {
                                    n = G.UIT.R,
                                    config = { align = "cm", padding = 0.3 },
                                    nodes = {
                                        {n=G.UIT.O, config={
                                            object = DynaText({
                                                string = {"An error occured in loading. The relevent data has been copied to your clipboard."}, 
                                                colours = {G.C.RED}, 
                                                shadow = true, 
                                                bump = true,
                                                spacing = 1,
                                                scale = 0.45,
                                                silent = true})
                                        }}
                                    }
                                },
                                {
                                    n = G.UIT.R,
                                    config = { align = "cm", padding = 0.3 },
                                    nodes = {
                                        {n=G.UIT.O, config={
                                            object = DynaText({
                                                string = {"Please post the data in the Thread or at https://github.com/WaffleDevs/ModProfiles"}, 
                                                colours = {G.C.RED}, 
                                                shadow = true, 
                                                bump = true,
                                                spacing = 1,
                                                scale = 0.45,
                                                silent = true})
                                        }}
                                    }
                                },
                            }
                        }
                    }
                })
            })
        end
    end 

    old_game_update(self,dt)
end

NFS.load(SMODS.current_mod.path.."/ui.lua")()

init()