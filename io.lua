mod_name = ...
local NFS = require("Mods/"..mod_name.."/nativefs")
require("love.system")

CHANNEL = love.thread.getChannel("io_channel")
OUT = love.thread.getChannel("io_out")
profiles_dir = love.filesystem.getSaveDirectory() .. "/mod_profiles"
mods_dir = love.filesystem.getSaveDirectory() .. "/Mods"


local function safeFunc(func, path, data)
    if string.find(path,profiles_dir) == 1 or string.find(path,mods_dir) == 1 then
        return func(path,data)
    else
        error("Path outside of allowed folder: " ..path)
    end
end


function recursiveCopy(old_dir, new_dir, depth, ret)
    depth = depth or 9
    for _, m in ipairs(NFS.getDirectoryItemsInfo(old_dir)) do
        local current_dir = old_dir .. "/" .. m.name
        local edit_dir = new_dir .. "/" .. m.name
        if m.type == "directory" and (m.name ~= mod_name and ((depth==9 and m.name~="lovely") or depth<9)) then
            if NFS.getInfo(current_dir) then
                safeFunc(NFS.createDirectory, edit_dir)
                if depth >= 0 then
                    recursiveCopy(current_dir, edit_dir, depth-1, ret)
                else
                    ret[current_dir] = "Recurse Depth Reached!"
                end
            end
            
        elseif m.type == "file" then
            if NFS.getInfo(current_dir) then
                local file,err= NFS.read(current_dir)

                if file ~= nil then 
                    safeFunc(NFS.write, edit_dir, file)
                else 
                    ret[current_dir] = err or "Copy Error!"
                end
            end
            
        end
    end
end
function recursiveDelete(profile_dir, delete_parent, depth, ret)
    depth = depth or 9

    for k, v in ipairs(NFS.getDirectoryItemsInfo(profile_dir)) do
        if v.type ~= "symlink" and ((depth==9 and v.name~="lovely") or depth<9) then
            if v.type == "directory" and v.name ~= mod_name and NFS.getInfo(profile_dir.."/"..v.name) then
                if depth > 0 then  
                    recursiveDelete(profile_dir.."/"..v.name, delete_parent, depth-1, ret) 
                    local success = safeFunc(NFS.remove,profile_dir.."/"..v.name)
                    if not success then 
                        ret[profile_dir.."/"..v.name] = "Deletion Fail"
                    end
                else
                    ret[profile_dir.."/"..v.name] = "Recurse Depth Reached!"
                end
            else
                local success = safeFunc(NFS.remove,profile_dir.."/"..v.name)
                if not success then 
                    ret[profile_dir.."/"..v.name] = "Deletion Fail"
                end
            end
        end
    end
    if delete_parent then
        safeFunc(NFS.remove,profile_dir)
    end
end

local id = 0

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
        id = id +1
        local path = request.profile
        local ret = {}
        if request.type == "delete" then
            if love.system.getOS() == 'Windows' then os.execute("attrib -r ./*.* /s") end
            recursiveDelete(request.profile,request.delete_params.delete_parent,nil, ret)
        end
        if request.type == "copy" then
            local target = request.copy_params.target
            if love.system.getOS() == 'Windows' then os.execute("attrib -r ./*.* /s") end
            recursiveCopy(path, target, nil, ret)
        end
        if request.type == "kill" then
            return
        end
        if type(ret) == "table" and #ret > 0 then
            OUT:push(ret)
        else
            OUT:push('Finished Task. Guessed Id: ' .. id)
        end
    end
end