local NFS = require("Mods/ModProfiles/nativefs")

CHANNEL = love.thread.getChannel("io_channel")
profiles_dir = love.filesystem.getSaveDirectory() .. "/mod_profiles"
mods_dir = love.filesystem.getSaveDirectory() .. "/Mods"

mod_name = ...

local function safeFunc(func, path, data)
    if string.find(path,profiles_dir) == 1 or string.find(path,mods_dir) == 1 then
        return func(path,data)
    else
        error("Path outside of allowed folder: " ..path)
    end
end

--[[
    Loop old_dir for all files.
    IF dir, create it in new dir, run recursive in it.

    If file, write it to new dir
    


]]--
function recursiveCopy(old_dir, new_dir, depth)
    depth = depth or 7
    
    for _, m in ipairs(NFS.getDirectoryItemsInfo(old_dir)) do
        local current_dir = old_dir .. "/" .. m.name
        local edit_dir = new_dir .. "/" .. m.name
        if m.type == "directory" and (m.name ~= mod_name and m.name ~= "lovely") then
            safeFunc(NFS.createDirectory, edit_dir)
            if depth >= 0 then
                recursiveCopy(current_dir, edit_dir, depth-1)
            end
        elseif m.type == "file" then
            local file,err= NFS.read(current_dir)

            if file ~= nil then 
                safeFunc(NFS.write, edit_dir, file)
            else 
                error(err)
            end
        end
    end
end
function recursiveDelete(profile_dir, delete_parent, depth)
    depth = depth or 9

    failed = 0
    succeeded = 0
    
    for k, v in ipairs(NFS.getDirectoryItemsInfo(profile_dir)) do
        if v.type ~= "symlink" and (v.name ~= "lovely" and depth == 9) then
            if v.type == "directory" and v.name ~= mod_name then
                if depth > 0 then  
                    recursiveDelete(profile_dir.."/"..v.name, delete_parent, depth-1) 
                    
                    local success = safeFunc(NFS.remove,profile_dir.."/"..v.name)
                    if success then succeeded = succeeded + 1 else failed = failed + 1 end
                end
            else
                local success = safeFunc(NFS.remove,profile_dir.."/"..v.name)
                if success then succeeded = succeeded + 1 else failed = failed + 1 end
            end
        end
    end
    if delete_parent then
        safeFunc(NFS.remove,profile_dir)
    end

end

---@class IO_Request: table
---@field type "delete"|"copy"
---@field mods_folder? boolean
---@field profile? string
---@field copy_params? {target:string,skip_extra:boolean}
---@field delete_params? {delete_parent:boolean}
while true do
    --Monitor the channel for any new requests

    ---@type IO_Request
    local request = CHANNEL:demand()

    if request then
        local path = request.profile
        if request.type == "delete" then
            recursiveDelete(request.profile,request.delete_params.delete_parent)
        end
        if request.type == "copy" then
            local target = request.copy_params.target
            recursiveCopy(path, target)
        end
        if request.type == "kill" then
            return
        end
    end
end