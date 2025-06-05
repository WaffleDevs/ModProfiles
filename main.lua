--[[
 File Structure::

 Root Balatro:
    configs - Mod Configs, steammodded stuff
    Mods - Mods folder
    1 / 2 / M1 / J1 - Profile folders. Cryptid and Jens changed.
    
    mod_profiles - This mods folder
        ExampleModpack - Modpack wow
            Mod1 
            Mod2 
            configs - ModConfigs folder, but profile specific.
            profiles - Save Data
        data - File containing MP persistant data. Only has the active profile. 
--]]

ModProfiles = ModProfiles or {}

-- MP Folders   REMEMBER TO CHECK lovely.toml FOR UPDATING SOME OF THESE. SOME HAVE TO BE HARDCODED :<
ModProfiles.main_dir = "/mod_profiles"
ModProfiles.mod_save_profiles_dir = "/.mp_profiles"
ModProfiles.mod_configs_dir = "/.mp_configs"

-- Base Folders (SMODS/LOVELY/VANILLA)
ModProfiles.mods_dir = "/Mods"
ModProfiles.configs_dir = "/configs"

ModProfiles.restart = false
ModProfiles.profiles = {}
ModProfiles.active_profile = "Default"
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
    for _, v in ipairs(getDirectoryItemsInfo(ModProfiles.main_dir)) do
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
            for _, m in ipairs(getDirectoryItemsInfo(ModProfiles.main_dir.."/"..v.name)) do
                if m.type == "directory" then
                    local disabled = love.filesystem.getInfo(ModProfiles.main_dir.."/"..v.name.."/"..m.name.."/.lovelyignore")
                    if not disabled then
                        if m.name ~= "lovely" then
                            ModProfiles.profiles[#ModProfiles.profiles].mods[#ModProfiles.profiles[#ModProfiles.profiles].mods+1] = {
                                mod_name = m.name,
                            }
                        end

                        local ok, chunk, err = pcall(love.filesystem.load, ModProfiles.main_dir.."/"..v.name.."/"..m.name.."/version.lua")
                        if ok and chunk then
                            local version = chunk()
                            ModProfiles.profiles[#ModProfiles.profiles].has_smods = version:match("%d%.%d%.%d~BETA%-%d%d%d%d%a%-STEAMODDED") and 1 or version:match("%d%.%d%.%d~ALPHA%-%d%d%d%d%a%-STEAMODDED") and 2 or 0
                        end
                    end
                elseif m.type=="file" then
                    if m.name == "profile.lua" then
                        local ok, chunk, err = pcall(love.filesystem.load, ModProfiles.main_dir.."/"..v.name.."/profile.lua")
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
    local profiles_directory_info = love.filesystem.getInfo(ModProfiles.main_dir, "directory")
    
    if profiles_directory_info then
        getProfiles()
    else
        love.filesystem.createDirectory(ModProfiles.main_dir)
        ModProfiles.createNewProfile("Default", true)
    end

    local data_info = love.filesystem.getInfo(ModProfiles.main_dir.."/data", "file")
    if data_info then
        local data = love.filesystem.read(ModProfiles.main_dir.."/data")
        ModProfiles.active_profile = data
        if ModProfiles.active_profile == "nil" then ModProfiles.active_profile = nil end
    else
        love.filesystem.write(ModProfiles.main_dir.."/data","Default")
    end
    sendInfoMessage("Active Profile: " .. (ModProfiles.active_profile or "None"), "ModProfiles-Init")
end

local function saveActiveProfileToFile()
    love.filesystem.write(ModProfiles.main_dir.."/data", tostring(ModProfiles.active_profile))
end

local function saveModConfigs()
    local profile_path = ModProfiles.main_dir.."/"..ModProfiles.active_profile..ModProfiles.mod_configs_dir
    if not love.filesystem.getInfo(profile_path, "directory") then
        love.filesystem.createDirectory(profile_path)
    end
    recursiveDelete(profile_path, nil, true)
    recursiveCopy(ModProfiles.configs_dir, profile_path, true)
end


local function createNewProfile(name, no_ui)
    local id = name
    local profile_path = ModProfiles.main_dir.."/"..id
    love.filesystem.createDirectory(profile_path)
    recursiveCopy(ModProfiles.mods_dir, profile_path, no_ui)
    ModProfiles.active_profile = name
    love.filesystem.createDirectory(profile_path..ModProfiles.mod_configs_dir)
    love.filesystem.createDirectory(profile_path..ModProfiles.mod_save_profiles_dir)
    saveModConfigs()
    G:save_progress()
    saveActiveProfileToFile()
end

local function loadProfile(profile)
    local profile_path = ModProfiles.main_dir.."/"..profile
    local profile_folder = love.filesystem.getInfo(profile_path, "directory")

    if not profile_folder then 
        error("Modprofile doesnt exist: "..profile)
        return
    end
    ModProfiles.active_profile = profile
    saveActiveProfileToFile()
    local config_folder = profile_path..ModProfiles.mod_configs_dir
    if love.filesystem.getInfo(config_folder, "directory") then
        recursiveDelete(ModProfiles.configs_dir, nil, true)
        recursiveCopy(config_folder, ModProfiles.configs_dir, true)
    end

    recursiveDelete(ModProfiles.mods_dir)
    recursiveCopy(profile_path, ModProfiles.mods_dir)

    ModProfiles.restart = true
end
local function deleteProfile(profile)
    local profile_path = ModProfiles.main_dir.."/"..profile
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
    old_game_update(self,dt)
end
local save_all_config = SMODS.save_all_config
SMODS.save_all_config = function ()
    local ret = save_all_config()
    ModProfiles.saveModConfigs()
    return ret
end
local hook_set_main_menu_UI = set_main_menu_UI
function set_main_menu_UI()
    local ret = hook_set_main_menu_UI()
    if love.filesystem.getInfo("/Profiles", "directory") then -- Directories hard coded, as they are for older verisons.
        G.FUNCS.updated_file_structure();
        for _, p in ipairs(getDirectoryItemsInfo("/Profiles")) do
            if p.type == "directory" then
                love.filesystem.createDirectory(ModProfiles.main_dir.."/"..p.name .. ModProfiles.mod_configs_dir)
                love.filesystem.createDirectory(ModProfiles.main_dir.."/"..p.name .. ModProfiles.mod_save_profiles_dir)

                for _, f in ipairs(getDirectoryItemsInfo("/Profiles/"..p.name)) do
                    if f.type == "directory" then
                        if f.name == "config" then
                            local old_dir = "/Profiles/"..p.name .. "/" .. f.name
                            if p.name == "nil" then p.name = "Default" end
                            local new_dir = ModProfiles.main_dir.."/"..p.name .. ModProfiles.mod_configs_dir

                            recursiveCopy(old_dir, new_dir)
                        else
                            local old_dir = "/Profiles/"..p.name .. "/" .. f.name
                            if p.name == "nil" then p.name = "Default" end
                            local new_dir = ModProfiles.main_dir.."/"..p.name .. ModProfiles.mod_save_profiles_dir..  "/" .. f.name
                            love.filesystem.createDirectory(ModProfiles.main_dir.."/"..p.name .. ModProfiles.mod_save_profiles_dir..  "/" .. f.name)

                            recursiveCopy(old_dir, new_dir)
                        end
                    end
                end
            end
        end
    end
    return ret
end


love.filesystem.load("Mods/"..ModProfiles.mod_folder.."/ui.lua")()

init()