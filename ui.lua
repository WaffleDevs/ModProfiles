-- Heavily inspired from SMODS/src/ui.lua. 

local function recalculateProfilesList(page)
    page = page or 1
    ModProfiles.getProfiles()
    ModProfiles.global_files = ModProfiles.getGlobalMods()

    local profilesPerPage = 4
    local startIndex = (page - 1) * profilesPerPage + 1
    local endIndex = startIndex + profilesPerPage - 1
    local totalPages = math.ceil(#ModProfiles.profiles / profilesPerPage)
    local currentPage = localize('k_page') .. ' ' .. page .. "/" .. totalPages
    local pageOptions = {}
    for i = 1, totalPages do
        table.insert(pageOptions, (localize('k_page') .. ' ' .. tostring(i) .. "/" .. totalPages))
    end
    local showingList = #ModProfiles.profiles > 0
    return currentPage, pageOptions, showingList, startIndex, endIndex, profilesPerPage
end

local function initProfileUiFunctions()
    -- for _, profileInfo in pairs(ModProfiles.profiles) do
    --     if not G.FUNCS["openProfileFolder_" .. profileInfo.name] then 
    --         G.FUNCS["openProfileFolder_" .. profileInfo.name] = function(e)
    --             love.system.openURL(ModProfiles.profiles_dir.."/"..profileInfo.name)
    --         end
    --     end
    -- end
end

local function createClickableProfileBox(profileInfo, scale)
    local is_active = profileInfo.name == ModProfiles.active_profile

    local button = UIBox_button {
        label = { " " .. profileInfo.name .. " " },
        shadow = true,
        scale = scale,
        colour = is_active and G.C.UI.TEXT_DARK or G.C.BOOSTER,
        text_colour = G.C.UI.TEXT_LIGHT,
        ref_table = profileInfo,
        button = "openProfileFolder",
        minh = 0.8,
        minw = 5
    }
    local delete = UIBox_button({
        label = { localize('b_profile_delete') },
        shadow = true,
        scale = scale*0.85,
        colour = G.C.RED,
        ref_table = profileInfo,
        button = "delete_profile_ui",
        minh = scale*1.5,
        minw = 1.3, col = true
    })
    local save = UIBox_button({
        label = { localize('b_profile_save') },
        shadow = true,
        scale = scale*0.85,
        colour = is_active and G.C.UI.TEXT_DARK or G.C.FILTER,
        ref_table = profileInfo,
        button = not is_active and "save_profile_ui",
        minh = scale*1.5,
        minw = 1.3, col = true
    })
    local load = UIBox_button({
        label = { localize('b_profile_load') },
        shadow = true,
        scale = scale*0.85,
        colour = is_active and G.C.UI.TEXT_DARK or G.C.GREEN,
        ref_table = profileInfo,
        button = not is_active and "load_profile_ui" or "",
        minh = scale*1.5,
        minw = 1.3, col = true
    })--- 

    if is_active and true then
        load.nodes[1].config.button = nil
        save.nodes[1].config.button = nil
    end

    return {
        n = G.UIT.R,
        config = { padding = 0, align = "cm" },
        nodes = {
            { n = G.UIT.C, config = { padding = 0.3, align = "cm" }, nodes = {  } },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { delete } },
            { n = G.UIT.C, config = { padding = 0.3, align = "cm" }, nodes = {  } },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { button } },
            { n = G.UIT.C, config = { padding = 0.3, align = "cm" }, nodes = {  } },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { save } },
            { n = G.UIT.C, config = { padding = 0.1, align = "cm" }, nodes = {  } },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { load } },
    }}
end

function staticModListContent()
    local scale = 0.75
    local currentPage, pageOptions, showingList = recalculateProfilesList()
    return {
        n = G.UIT.ROOT,
        config = {
            minh = 6,
            r = 0.1,
            minw = 10,
            align = "tm",
            padding = 0.2,
            colour = G.C.BLACK
        },
        nodes = {
            -- row container
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.05 },
                nodes = {
                    -- column container
                    {
                        n = G.UIT.C,
                        config = { align = "cm", minw = 3, padding = 0.2, r = 0.1, colour = G.C.CLEAR },
                        nodes = {
                            -- title row
                            {
                                n = G.UIT.R,
                                config = {  
                                    padding = 0.05,
                                    align = "cm"
                                },
                                nodes = {   
                                    {
                                        n = G.UIT.C,
                                        config = { align = "cm", padding = 0.8 },
                                        nodes = {}
                                    },
                                    UIBox_button({
                                        label = { localize('b_profiles_list') },
                                        shadow = true,
                                        scale = scale*0.85,
                                        colour = G.C.BOOSTER,
                                        button = "openProfilesDirectory",
                                        minh = scale,
                                        minw = 4.5,
                                        col=true
                                    }),
                                    {
                                        n = G.UIT.C,
                                        config = { align = "cr", padding = .8 },
                                        nodes = {}
                                    },
                                    UIBox_button({
                                        label = { localize('b_profile_new') },
                                        shadow = true,
                                        scale = scale*0.85,
                                        colour = G.C.SECONDARY_SET.Planet,
                                        button = "new_profile_ui",
                                        minh = scale,
                                        minw = 1.5,
                                        col=true
                                    }),
                                }
                            },

                            -- add some empty rows for spacing
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },

                            -- dynamic content rendered in this row container
                            -- list of 4 mods on the current page
                            {
                                n = G.UIT.R,
                                config = {
                                    padding = 0.05,
                                    align = "cm",
                                    minh = 2,
                                    minw = 4
                                },
                                nodes = {
                                    {n=G.UIT.O, config={id = 'profilesList', object = Moveable()}},
                                }
                            },

                            -- another empty row for spacing
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.3 },
                                nodes = {}
                            },

                            -- page selector
                            -- does not appear when list of mods is empty
                            showingList and SMODS.GUI.createOptionSelector({label = "", scale = 0.8, options = pageOptions, opt_callback = 'update_profile_list', no_pips = true, current_option = (
                                    currentPage
                            )}) or nil
                        }
                    },
                }
            },
        }
    }
end

function dynamicModListContent(page)
    local scale = 0.75
    local _, __, showingList, startIndex, endIndex, profilesPerPage = recalculateProfilesList(page)

    local modNodes = {}

    -- If no mods are loaded, show a default message
    if showingList == false then
        table.insert(modNodes, {
            n = G.UIT.R,
            config = {
                padding = 0,
                align = "cm"
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        text = localize('b_no_mods'),
                        shadow = true,
                        scale = scale * 0.5,
                        colour = G.C.UI.TEXT_DARK
                    }
                }
            }
        })
    else
        local modCount = 0
        local id = 0
        

        for _, profileInfo in ipairs(ModProfiles.profiles) do
            if modCount >= profilesPerPage then break end
            id = id + 1
            if id >= startIndex and id <= endIndex then
                table.insert(modNodes, createClickableProfileBox(profileInfo, scale * 0.5))
                modCount = modCount + 1
            end
        end
    end

    return {
        n = G.UIT.C,
        config = {
            r = 0.1,
            align = "cm",
            padding = 0.2,
        },
        nodes = modNodes
    }
end

local function createProfileConfirmationDialog(args)
    if not args.profile then return error("need profile") end

    args.confirm_text = args.confirm_text or localize('b_profile_save_yes')
    args.deny_text = args.deny_text or localize('b_profile_save_no')
    args.question_text = args.question_text or localize('b_profile_save_no')
    args.confirm_func = args.confirm_func or "exit_confirmation"
    -- flip_confirm_cancel_colours
    args.fccc = args.fccc or false
    return create_UIBox_generic_options({
        back_func = "exit_confirmation",
        no_back = true,
        contents = {
            {
                n = G.UIT.R,
                config = {
                    padding = 0,
                    align = "tm"
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.3 },
                        nodes = {
                            {n = G.UIT.T, config = {
                                text = args.question_text,
                                shadow = true,
                                scale = 0.45,
                                colour = G.C.DARK_EDITION,
                            }},
                        }
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.3 },
                        nodes = {
                            UIBox_button({
                                label = { args.confirm_text },
                                shadow = true,
                                scale = .45,
                                colour = args.fcc and G.C.GREEN or G.C.RED,
                                ref_table = args.profile,
                                button = args.confirm_func,
                                minh = .6,
                                minw = 2.5,
                                col = true
                            }),
                            UIBox_button({
                                label = { args.deny_text },
                                shadow = true,
                                scale = .45,
                                colour = args.fcc and G.C.RED or G.C.GREEN,
                                button = "exit_confirmation",
                                minh = .6,
                                minw = 2.5,
                                col = true
                            }),
                        }
                    },
                }
            }
        }
    })
end

G.FUNCS.update_profile_list = function ( args )
    if not args or not args.cycle_config then return end
    SMODS.GUI.DynamicUIManager.updateDynamicAreas({ 
        ["profilesList"] = ModProfiles.UI.dynamicModListContent(args.cycle_config.current_option)
    })
end

G.FUNCS.exit_confirmation = function ( args )
   G.FUNCS.mods_button( args )
   G.E_MANAGER:add_event(Event({
        delay=0.2,
        func = function()
            local tab = G.OVERLAY_MENU:get_UIE_by_ID("tab_but_Profiles")
            tab.config.chosen = true
            G.OVERLAY_MENU:get_UIE_by_ID("tab_but_Mods").config.chosen = false
            G.FUNCS.change_tab( tab )
            return true
        end,
        blocking = false,
        blockable = false
    }))
end
    
G.FUNCS.save_profile_ui = function (e)
    local profileInfo = e.config.ref_table
    G.FUNCS.overlay_menu({
        definition = createProfileConfirmationDialog({
            profile = profileInfo,
            question_text = "Are you sure you want to overwrite this save?",
            confirm_func = "save_profile"
        })
    })
end

G.FUNCS.save_profile = function (e)
    local profileInfo = e.config.ref_table
   ModProfiles.deleteProfile(profileInfo.name)
   ModProfiles.createNewProfile(profileInfo.name)
   play_sound('highlight2', .5, 0.4)
   G.FUNCS.exit_confirmation(e)
end



G.FUNCS.delete_profile_ui = function (e)
    local profileInfo = e.config.ref_table
    G.FUNCS.overlay_menu({
        definition = createProfileConfirmationDialog({
            profile = profileInfo,
            question_text = "Are you sure you want to delete this save?",
            confirm_func = "delete_profile",
            fccc = true
        })
    })
end

G.FUNCS.delete_profile = function (e)
    local profileInfo = e.config.ref_table
   ModProfiles.deleteProfile(profileInfo.name)
   play_sound('crumple1', 0.8, 1);
   G.FUNCS.exit_confirmation(e)
end

function checkEdits(profile)
    if ModProfiles.active_profile == nil then
        return true
    end

    local result = true

    for _, m in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.mods_dir)) do
        if (not (m.type == "symlink" or m.name == "lovely")) and ((ModProfiles.global_files and not ModProfiles.global_files[m.name]) or (not ModProfiles.global_files)) then
            if not NFS.getInfo(ModProfiles.profiles_dir.."/"..ModProfiles.active_profile.."/"..m.name) and not ModProfiles.global_files[m.name] then 
                print("Mods/"..m.name)
                result = false 
            else
                for _, v in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.mods_dir.."/"..m.name)) do
                    if not (v.type == "symlink" or v.name == "lovely") then
                        if not NFS.getInfo(ModProfiles.profiles_dir.."/"..ModProfiles.active_profile.."/"..m.name.."/"..v.name) then 
                            print("/"..m.name.."/"..v.name)
                            result = false 
                        end
                    end
                end
            end
        end
    end

    return result
end

G.FUNCS.load_profile_ui = function (e)
    local profileInfo = e.config.ref_table
    local text = "Are you sure you want to load?"
    local is_changed = not checkEdits(profileInfo.name)
    if is_changed then
        text = "You have unsaved changes. " .. text
    end
    G.FUNCS.overlay_menu({
        definition = createProfileConfirmationDialog({
            profile = profileInfo,
            question_text = text,
            confirm_func = "load_profile",
            fccc = is_changed
        })
    })
end

G.FUNCS.load_profile = function (e)
    local profileInfo = e.config.ref_table
   ModProfiles.loadProfile(profileInfo.name)
   play_sound('crumple1', 0.8, 1);
   G.FUNCS.exit_confirmation(e)
   SMODS.restart_game()
end

G.FUNCS.new_profile_ui = function ()
    local value = {name=""}
    G.FUNCS.overlay_menu({definition = 
    create_UIBox_generic_options({
        back_func = "exit_confirmation",
        no_back = true,
        contents = {
            {n = G.UIT.R, config = { padding = 0, align = "cm" }, nodes = {
                {n=G.UIT.R, config={align = "cm", padding = 0.12, emboss = 0.1, colour = G.C.L_BLACK, r = 0.1}, nodes={
                    {n = G.UIT.T, config = {
                        id="testt",
                        text = "Set Profile Name",
                        shadow = true,
                        scale = 0.45,
                        colour = G.C.EDITION,
                    }}
                }},
                { n = G.UIT.R, config = { align = "cm", padding = 0.3 },
                        nodes = {
                            
                            create_text_input({
                                ref_table = value, ref_value = 'name'
                            }), 
                            
                    },
                },
                {n = G.UIT.R, config = { align = "cm", padding = 0.3 },
                    nodes = {
                        UIBox_button({
                            label = { "Confirm" },
                            shadow = true, scale = .45,
                            colour = G.C.GREEN,
                            ref_table = value,
                            button = "new_profile",
                            minh = .6, minw = 2.5, col = true
                        }),
                        UIBox_button({
                            label = { "Cancel" },
                            shadow = true, scale = .45,
                            colour = G.C.RED,
                            button = "exit_confirmation",
                            minh = .6, minw = 2.5, col = true
                        }),
                    }
                },
            }}
        }
    })
        

})
G.OVERLAY_MENU:get_UIE_by_ID("testt").UIBox:recalculate()
end
G.FUNCS.new_profile = function(args)
    ModProfiles.createNewProfile(args.config.ref_table.name)
    G.FUNCS.exit_confirmation(args)
end
G.FUNCS.openProfileFolder = function(e)
    local profileInfo = e.config.ref_table
    love.system.openURL(ModProfiles.profiles_dir.."/"..profileInfo.name)
end

G.FUNCS.openProfilesDirectory = function(e)
    love.system.openURL(ModProfiles.profiles_dir)
end

initProfileUiFunctions()

ModProfiles.checkEdits = checkEdits
ModProfiles.UI = {}

ModProfiles.UI.initProfileUiFunctions = initProfileUiFunctions
ModProfiles.UI.staticModListContent = staticModListContent
ModProfiles.UI.dynamicModListContent = dynamicModListContent


-- watch lua Mods/ModProfiles/ui.lua