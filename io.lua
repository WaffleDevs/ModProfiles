local NFS = require("Mods/ModProfiles/nativefs")

CHANNEL = love.thread.getChannel("io_channel")
profiles_dir = love.filesystem.getSaveDirectory() .. "/mod_profiles"
mods_dir = love.filesystem.getSaveDirectory() .. "/Mods"

local function safeFunc(func, path, data)
    if string.find(path,profiles_dir) == 1 or string.find(path,mods_dir) == 1 then
        return func(path,data)
    else
        error("Path outside of allowed folder: " ..path)
    end
end


function recursiveCopy(old_dir, new_dir, skip_extra, depth)
    depth = depth or 7
    for k, v in ipairs(NFS.getDirectoryItemsInfo(old_dir)) do
            if v.type == "directory" then
                safeFunc(NFS.createDirectory,new_dir.."/"..v.name)
                if depth > 0 then 
                    recursiveCopy(old_dir.."/"..v.name, new_dir.."/"..v.name, depth-1) 
                end
            elseif not (skip_extra and (v.type == "symlink" or (v.name == "lovely" and depth == 7))) then
                local file = safeFunc(NFS.read,old_dir.."/"..v.name)
                safeFunc(NFS.write,new_dir.."/"..v.name, file)
            end
    end
end
function recursiveDelete(profile_dir, delete_parent, depth)
    depth = depth or 7

    failed = 0
    succeeded = 0
    
    for k, v in ipairs(NFS.getDirectoryItemsInfo(profile_dir)) do
        if v.type ~= "symlink" then
            if v.type == "directory" then
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

    return {failed = failed, succeeded = succeeded}
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
            local skip_extra = request.copy_params.skip_extra
            recursiveCopy(path, target, skip_extra)
        end
    end
end