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

ModProfiles = ModProfiles or {}

ModProfiles.profiles_dir = "/mod_profiles"
ModProfiles.mods_dir = "/Mods"

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

ModProfiles.config = SMODS.current_mod.config
SMODS.current_mod.config_tab = function()
    return {n = G.UIT.ROOT, config = {
        r = .2, colour = G.C.BLACK
    }, nodes = {
        {n = G.UIT.C, config = { padding = .5,}, nodes = {
            create_toggle({label = "Per Profile Mod Configs", ref_table = ModProfiles.config, ref_value = 'profile_mod_configs', info = {"As name implies. Mod configs are seperate between modpacks."}, active_colour = G.C.RED}) or nil,
        }}
    }}
end

-- From NativeFS Copyright 2020 megagrump@pm.me
local function getDirectoryItemsInfo(path, filtertype)
    local items = {}
    local files = love.filesystem.getDirectoryItems(path)
    for i = 1, #files do
        local filepath = string.format('%s/%s', path, files[i])
        local info = love.filesystem.getInfo(filepath, filtertype)
        if info then
            info.name = files[i]
            table.insert(items, info)
        end
    end
    return items
end

local function getProfiles() 
    ModProfiles.profiles = {}
    local profile_count = 0
    -- profiles
    for _, v in ipairs(getDirectoryItemsInfo(ModProfiles.profiles_dir)) do
        if v.type == "file" and not v.name == "data" then
            print('Odd file in Profiles Dir. ' .. v.name)
        end

        if v.type == "directory" then
            count = profile_count + 1
            ModProfiles.profiles[#ModProfiles.profiles+1] = {
                name = v.name,
                mods = {},
                has_smods=false
            }

            --mods

            for _, m in ipairs(getDirectoryItemsInfo(ModProfiles.profiles_dir.."/"..v.name)) do
                if m.type == "directory" then
                    local disabled = love.filesystem.getInfo(ModProfiles.profiles_dir.."/"..v.name.."/"..m.name.."/.lovelyignore")
                    if not disabled then
                        if m.name ~= "lovely" then
                            ModProfiles.profiles[#ModProfiles.profiles].mods[#ModProfiles.profiles[#ModProfiles.profiles].mods+1] = {
                                mod_name = m.name,
                            }
                        end

                        local ok, chunk, err = pcall(love.filesystem.load, ModProfiles.profiles_dir.."/"..v.name.."/"..m.name.."/version.lua")
                        if ok and chunk then
                            local version = chunk()
                            ModProfiles.profiles[#ModProfiles.profiles].has_smods = version:match("%d%.%d%.%d~BETA%-%d%d%d%d%a%-STEAMODDED") and 1 or version:match("%d%.%d%.%d~ALPHA%-%d%d%d%d%a%-STEAMODDED") and 2 or 0
                        end
                    end
                elseif m.type=="file" then
                    if m.name == "profile.lua" then
                        local ok, chunk, err = pcall(love.filesystem.load, ModProfiles.profiles_dir.."/"..v.name.."/profile.lua")
                        if ok and chunk then
                            local profile_info = chunk()
                            ModProfiles.profiles[#ModProfiles.profiles].profile_info = profile_info
                        end
                    end
                end
            end

        end
    end
end

function recursiveCopy(old_dir, new_dir, no_ui)
    local id = io_channel:push({
        type="copy",
        profile=old_dir,
        copy_params={
            target=new_dir,
        }, 
        no_ui = no_ui
    })
    ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count + 1
end
function recursiveDelete(profile_dir, delete_parent, no_ui)
    local id = io_channel:push({
        type="delete",
        profile=profile_dir,
        delete_params={
            delete_parent=delete_parent
        }, 
        no_ui = no_ui
    })
    ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count + 1
end

local function init()
    local profiles_directory_info = love.filesystem.getInfo(ModProfiles.profiles_dir, "directory")
    
    if profiles_directory_info then
        getProfiles()
    else
        love.filesystem.createDirectory(ModProfiles.profiles_dir)
    end

    local data_info = love.filesystem.getInfo(ModProfiles.profiles_dir.."/data", "file")
    if data_info then
        local data = love.filesystem.read(ModProfiles.profiles_dir.."/data")
        ModProfiles.active_profile = data
        if ModProfiles.active_profile == "nil" then ModProfiles.active_profile = nil end
    else
        love.filesystem.write(ModProfiles.profiles_dir.."/data","nil")
    end

    sendInfoMessage("Active Profile: " .. (ModProfiles.active_profile or "None"), "ModProfiles-Init")
end

local function saveActiveProfileToFile()
    love.filesystem.write(ModProfiles.profiles_dir.."/data", tostring(ModProfiles.active_profile))
end

local function saveModConfigs()
    local profile_path = "/Profiles/"..ModProfiles.active_profile.."/config"
    if not love.filesystem.getInfo(profile_path, "directory") then
        love.filesystem.createDirectory(profile_path)
    end
    print("Saving Config")
    recursiveDelete(profile_path, nil, true)
    recursiveCopy("/config", profile_path, true)
end


local function createNewProfile(name) 
    local id = name
    local profile_path = ModProfiles.profiles_dir.."/"..id
    love.filesystem.createDirectory(profile_path)
    recursiveCopy(ModProfiles.mods_dir, profile_path)
    if not ModProfiles.active_profile then ModProfiles.active_profile = name end
    love.filesystem.createDirectory(profile_path.."/config")
    saveActiveProfileToFile()
end

local function loadProfile(profile)
    local profile_path = ModProfiles.profiles_dir.."/"..profile
    local profile_folder = love.filesystem.getInfo(profile_path, "directory")

    if not profile_folder then 
        error("Modprofile doesnt exist: "..profile)
        return
    end
    ModProfiles.active_profile = profile
    saveActiveProfileToFile()

    print(love.filesystem.getInfo("/Profiles/"..profile.."/config", "directory"))    
    if love.filesystem.getInfo("/Profiles/"..profile.."/config", "directory") then
        recursiveDelete("/config", nil, true)
        recursiveCopy("/Profiles/"..profile.."/config", "/config", true)
    end

    recursiveDelete(ModProfiles.mods_dir)
    recursiveCopy(profile_path, ModProfiles.mods_dir)

    ModProfiles.restart = true
end
local function deleteProfile(profile)
    local profile_path = ModProfiles.profiles_dir.."/"..profile
    local profile_folder = love.filesystem.getInfo(profile_path, "directory")

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

ModProfiles.saveModConfigs = saveModConfigs

ModProfiles.createNewProfile = createNewProfile
ModProfiles.loadProfile = loadProfile
ModProfiles.deleteProfile = deleteProfile
ModProfiles.getProfiles = getProfiles

local old_game_update = Game.update
local second_count = 0
function Game:update(dt)
    if ModProfiles.io_thread.thread:getError() then
        error(ModProfiles.io_thread.thread:getError())
    end

    if type(ModProfiles.io_thread.out:peek())  ~= "nil" then 
        -- Code to run at 'End of task'. Out will always recieve a message at end of task, unless fatal error.
        local ret = ModProfiles.io_thread.out:pop();
        ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count-1
        ModProfiles.io_thread.active = ModProfiles.io_thread.proc_count ~= 0
            -- All tasks done, run ending codes
            print(type(ret))
        if type(ret) == "string" then
            if not ModProfiles.io_thread.active then
                G.FUNCS.exit_confirmation()
                play_sound('holo1', 1.5, 1)
                if ModProfiles.restart then SMODS.restart_game() end
            end
        elseif type(ret) == "table" and not ret.no_ui then
            sendWarnMessage("Something fucked up chat", "ModProfiles-IO_Thread")
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
    -- if second_count > 10 then
    --     second_count = 0
    --     saveModConfigs()
    -- end
    -- if ModProfiles.io_thread.proc_count == 0 then
    --     second_count = second_count + dt
    -- end 
    old_game_update(self,dt)
end
local save_all_config = SMODS.save_all_config
SMODS.save_all_config = function ()
    local ret = save_all_config()
    ModProfiles.saveModConfigs()
    return ret
end

love.filesystem.load("Mods/"..ModProfiles.mod_folder.."/ui.lua")()

init()