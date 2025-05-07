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
    active_procs = {}
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
local function safeFunc(func, path, data)
    if string.find(path, ModProfiles.profiles_dir) == 1 or string.find(path,ModProfiles.mods_dir) == 1 then
        return func(path,data)
    else
        error("Path outside of allowed folder: " ..path)
    end
end

function recursiveCopy(old_dir, new_dir, depth)
    -- print('s-------')
    -- print("call on " .. old_dir)
    -- depth = depth or 9
    -- for _, m in ipairs(NFS.getDirectoryItemsInfo(old_dir)) do
    --     local current_dir = old_dir .. "/" .. m.name
    --     local edit_dir = new_dir .. "/" .. m.name
    --     print("c "..current_dir)
    --     print("e "..edit_dir)
    --     if m.type == "directory" and (m.name ~= mod_name and m.name ~= "lovely") then
    --         safeFunc(NFS.createDirectory, edit_dir)
    --         if depth >= 0 then
    --             recursiveCopy(current_dir, edit_dir, depth-1)
    --         end
    --     elseif m.type == "file" then
    --         local file,err= NFS.read(current_dir)

    --         if file ~= nil then 
    --             safeFunc(NFS.write, edit_dir, file)
    --         else 
    --             error(err)
    --         end
    --     end
    -- end
    -- print('fin')
    -- print('e-------')
    
    -- if depth==9 then print('finfinfinfinfinfinfin') end
    local id = io_channel:push({
        type="copy",
        profile=old_dir,
        copy_params={
            target=new_dir,
        }
    })
    ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count + 1
    --ModProfiles.io_thread.active_procs[#ModProfiles.io_thread.active_procs+1] = id
end
function recursiveDelete(profile_dir, delete_parent, depth)
    -- depth = depth or 9
    -- failed = 0
    -- succeeded = 0
    
    -- for k, v in ipairs(NFS.getDirectoryItemsInfo(profile_dir)) do
    --     if v.type ~= "symlink" and (v.name ~= "lovely" and depth == 9) then
    --         if v.type == "directory" and v.name ~= mod_name then
    --             if depth > 0 then  
    --                 recursiveDelete(profile_dir.."/"..v.name, delete_parent, depth-1) 
    --                 print('dirdel')
    --                 local success = safeFunc(NFS.remove,profile_dir.."/"..v.name)
    --                 if success then succeeded = succeeded + 1 else failed = failed + 1 end
    --             end
    --         else
    --             print('filedel')
    --             local success = safeFunc(NFS.remove,profile_dir.."/"..v.name)
    --             if success then succeeded = succeeded + 1 else failed = failed + 1 end
    --         end
    --     end
    -- end
    -- if delete_parent then
    --     safeFunc(NFS.remove,profile_dir)
    -- end

    -- print({failed=failed,succeeded=succeeded})

    local id = io_channel:push({
        type="delete",
        profile=profile_dir,
        delete_params={
            delete_parent=delete_parent
        }
    })
    ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count + 1
    --ModProfiles.io_thread.active_procs[#ModProfiles.io_thread.active_procs+1] = id
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

    sendInfoMessage("Active Profile: " .. (ModProfiles.active_profile or "None"), "ModProfiles-Init")
end

local function createNewProfile(name) 
    local id = name
    local profile_path = ModProfiles.profiles_dir.."/"..id
    NFS.createDirectory(profile_path)
    recursiveCopy(ModProfiles.mods_dir, profile_path)
    if not ModProfiles.active_profile then ModProfiles.active_profile = name end
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
    NFS.write(ModProfiles.profiles_dir.."/data", tostring(ModProfiles.active_profile))

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
        NFS.write(ModProfiles.profiles_dir.."/data", tostring(ModProfiles.active_profile))
    end

    recursiveDelete(profile_path,true)
end


ModProfiles.createNewProfile = createNewProfile
ModProfiles.loadProfile = loadProfile
ModProfiles.deleteProfile = deleteProfile
ModProfiles.getProfiles = getProfiles

local old_game_update = Game.update
function Game:update(dt)

    -- for i, v in ipairs(ModProfiles.io_thread.active_procs) do
    --     local read = ModProfiles.io_thread.channel:hasRead(v)
    --     if read then
    --         table.remove(ModProfiles.io_thread.active_procs, i)
    --         print(v .. " fin " .. #ModProfiles.io_thread.active_procs)
    --         G.FUNCS.exit_confirmation()
    --     end
    -- end


    -- ModProfiles.io_thread.active = #ModProfiles.io_thread.active_procs ~= 0

    -- if not ModProfiles.io_thread.active and ModProfiles.restart then 
    --     --SMODS.restart_game() 
    --     print("RESTST") -- Todo: make work
    -- end
    if ModProfiles.io_thread.thread:getError() then
        error(ModProfiles.io_thread.thread:getError())
    end

    if type(ModProfiles.io_thread.out:peek()) == "string" then 
        local str = ModProfiles.io_thread.out:pop();
        ModProfiles.io_thread.proc_count = ModProfiles.io_thread.proc_count-1
        ModProfiles.io_thread.active = ModProfiles.io_thread.proc_count ~= 0
        print(str .. " " .. tostring(ModProfiles.io_thread.active)); 
        if not ModProfiles.io_thread.active and ModProfiles.restart then
            SMODS.restart_game() 
        end
    end





    -- if previous_count ~= ModProfiles.io_thread.channel:getCount() then -- After any process ends
    --     previous_count = ModProfiles.io_thread.channel:getCount()

    --     G.FUNCS.exit_confirmation()
    -- end
    -- if ModProfiles.io_thread.channel:getCount() == 0 and ModProfiles.io_thread.active then -- Inactive
    --     print("count " .. ModProfiles.io_thread.channel:getCount())
        
    --     if ModProfiles.restart then 
    --         --SMODS.restart_game() 
    --         print("RESTST") -- Todo: make work
    --     end
    -- end

    -- print(ModProfiles.io_thread.channel:getCount())
    
    -- ModProfiles.io_thread.active = ModProfiles.io_thread.channel:getCount() > 0
    old_game_update(self,dt)
end

NFS.load(SMODS.current_mod.path.."/ui.lua")()

init()