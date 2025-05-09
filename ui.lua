-- Heavily inspired from SMODS/src/ui.lua. 

local function recalculateProfilesList(page)
    page = page or 1
    ModProfiles.getProfiles()

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

local function createClickableProfileBox(profileInfo, scale)
    local is_active = profileInfo.name == ModProfiles.active_profile

    local button = UIBox_button {
        id = is_active and "active_profile_box" or nil,
        label = { profileInfo.name },
        shadow = true,
        scale = scale,
        colour = is_active and G.C.BOOSTER or G.C.UI.TEXT_DARK,--G.C.UI.TEXT_DARK or G.C.BOOSTER,
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
        colour = is_active and darken(G.C.RED, .4) or G.C.RED,
        ref_table = profileInfo,
        button = "delete_modprofile_ui",
        minh = scale*1.5,
        minw = 1.3, col = true
    })
    local save = UIBox_button({
        label = { localize('b_profile_save') },
        shadow = true,
        scale = scale*0.85,
        colour = is_active and darken(G.C.FILTER, .3) or G.C.FILTER,
        ref_table = profileInfo,
        button = "save_modprofile_ui",
        minh = scale*1.5,
        minw = 1.3, col = true
    })
    local load = UIBox_button({
        label = { localize('b_profile_load') },
        shadow = true,
        scale = scale*0.85,
        colour = is_active and G.C.UI.TEXT_DARK or G.C.GREEN,
        ref_table = profileInfo,
        button = not is_active and "load_modprofile_ui" or "",
        minh = scale*1.5,
        minw = 1.3, col = true
    })--- 

    if is_active and true then
        load.nodes[1].config.button = nil
    end

    return {
        n = G.UIT.R,
        config = { padding = 0, align = "cm" },
        nodes = {
            { n = G.UIT.C, config = { padding = 0.3, align = "cm" }, nodes = {  } },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { delete } },
            { n = G.UIT.C, config = { padding = 0.3, align = "cm" }, nodes = {  } },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { button }} ,
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
            colour = G.C.BLACK, id="top_level_profiles_tab"
        },
        nodes = {
            -- row container
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.05},
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
                                        button = "new_modprofile_ui",
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
                    args.custom_node and args.custom_node or {
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
                                colour = args.fccc and G.C.UI.TEXT_INACTIVE or G.C.RED,
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
                                colour = args.fccc and G.C.RED or G.C.UI.TEXT_INACTIVE,
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
    
G.FUNCS.save_modprofile_ui = function (e)
    local profileInfo = e.config.ref_table
    G.FUNCS.overlay_menu({
        definition = createProfileConfirmationDialog({
            profile = profileInfo,
            question_text = "Are you sure you want to overwrite this save?",
            confirm_func = "save_modprofile"
        })
    })
end

G.FUNCS.save_modprofile = function (e)
    local profileInfo = e.config.ref_table
    ModProfiles.deleteProfile(profileInfo.name)
    ModProfiles.createNewProfile(profileInfo.name)
    play_sound('highlight2', .5, 0.4)
    G.FUNCS.overlay_menu({
        definition = create_UIBox_generic_options({
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
                                {n=G.UIT.O, config={
                                    object = DynaText({
                                        string = {"Saving profile..."}, 
                                        colours = {G.C.UI.TEXT_LIGHT}, 
                                        shadow = true, 
                                        float = true,
                                        spacing = 1.5,
                                        scale = 0.6,
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
                                        string = {"This menu will close automatically.", "You may also click 'Esc', but this can cause issues."}, 
                                        colours = {G.C.JOKER_GREY}, 
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

G.FUNCS.delete_modprofile_ui = function (e)
    local profileInfo = e.config.ref_table
    G.FUNCS.overlay_menu({
        definition = createProfileConfirmationDialog({
            profile = profileInfo,
            question_text = "Are you sure you want to delete this save?",
            confirm_func = "delete_modprofile",
            fccc = true
        })
    })
end

G.FUNCS.delete_modprofile = function (e)
    local profileInfo = e.config.ref_table
    ModProfiles.deleteProfile(profileInfo.name)
    play_sound('crumple1', 0.8, 1);
end

function checkEdits(profile)
    if not ModProfiles.active_profile then
        return false
    end

    local result = false
    local modified_mods = {}
    for _, m in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.mods_dir)) do
        if (not (m.type == "symlink" or m.name == "lovely" or m.name == ModProfiles.mod_folder)) then
            if not NFS.getInfo(ModProfiles.profiles_dir.."/"..ModProfiles.active_profile.."/"..m.name) then 
                print(m.name)
                result = true 
                modified_mods[#modified_mods+1] = m.name
            else
                for _, v in ipairs(NFS.getDirectoryItemsInfo(ModProfiles.mods_dir.."/"..m.name)) do
                    if not (v.type == "symlink" or v.name == "lovely") then
                        if not NFS.getInfo(ModProfiles.profiles_dir.."/"..ModProfiles.active_profile.."/"..m.name.."/"..v.name) then 
                            print(m.name.."/"..v.name)
                            result = true 
                            modified_mods[#modified_mods+1] = m.name
                        end
                    end
                end
            end
        end
    end

    return result, modified_mods
end

G.FUNCS.load_modprofile_ui = function (e)
    local profileInfo = e.config.ref_table
    local is_changed, files = checkEdits(profileInfo.name)
    print(is_changed)
    local has_smods = profileInfo.has_smods

    local main_nodes = {
        (is_changed or ModProfiles.active_profile==nil) and {n = G.UIT.T, config = {
            text = "You have unsaved changes.",
            shadow = true,
            scale = 0.45,
            colour = G.C.RED,
        }} or nil,
        {n = G.UIT.T, config = {
            text = "Are you sure you want to load?",
            shadow = true,
            scale = 0.45,
            colour = G.C.UI.TEXT_LIGHT,
        }}
    }
    if is_changed or has_smods ~= 1 then
        play_sound("voice10", 1)
    end
    if has_smods ~= 1 then 
        main_nodes = {
            {n=G.UIT.O, config={
                object = DynaText({
                    string = {has_smods ~= 2 and "WARNING: This profile does not has SMODS. ModProfiles will NOT work." or "WARNING: This profile has an old version of SMODS. ModProfiles might not work."}, 
                    colours = {has_smods ~= 2 and G.C.RED or G.C.FILTER}, 
                    shadow = true, 
                    bump = true,
                    spacing = 1,
                    scale = 0.45,
                    silent = true})
            }}
        }
    end
    
    local edited_mods_node = {
        n = G.UIT.C,
        config = { align = "cm", padding = 0.1},
        nodes = {
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.1 },
                nodes = {
                    {n = G.UIT.T, config = {
                        align = "cm", 
                        text = "Modified Mods: ",
                        shadow = true,
                        scale = 0.45,
                        colour = G.C.UI.TEXT_LIGHT,
                    }},
                    
                },
            },
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.1 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cl", padding = 0.1, minw = 5},
                        nodes = {
                            
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "cr", padding = 0.1, minw = 5},
                        nodes = {
                           
                        }
                    }
                },
            },
        }
    }

    if is_changed and files then
        local mods_nodes = {}

        for i = 1, #files, 2 do
            local file1 = files[i]
            local file2 = files[i+1] or nil

            edited_mods_node.nodes[2].nodes[1].nodes[#edited_mods_node.nodes[2].nodes[1].nodes+1] = {
                n = G.UIT.R,
                config = {padding = 0.1 },
                nodes = {
                    {n = G.UIT.T, config = {
                        text = i .. ": " .. file1,
                        shadow = true,
                        scale = 0.45,
                        colour = G.C.UI.TEXT_LIGHT,
                        align = "cl",
                        padding = .1
                    }},
                }
            }
            if file2 then
                edited_mods_node.nodes[2].nodes[2].nodes[#edited_mods_node.nodes[2].nodes[1].nodes+1] = {
                    n = G.UIT.R,
                    config = {padding = 0.1 },
                    nodes = {
                        {n = G.UIT.T, config = {
                            text = i+1 .. ": " .. file2,
                            shadow = true,
                            scale = 0.45,
                            colour = G.C.UI.TEXT_LIGHT,
                            align = "cr",
                            padding = .1
                        }},
                    }
                }
            end
        end
    end


    local node = {
        n = G.UIT.R,
        config = { align = "cm", padding = 0.3 },
        nodes = {
            {
            n = G.UIT.C,
            config = { align = "cm", padding = 0.1 },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.1 },
                    nodes = main_nodes
                },
                is_changed and {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.3 },
                    nodes = {edited_mods_node}
                } or nil
            }
        }}
    }
    
    G.FUNCS.overlay_menu({
        definition = create_UIBox_generic_options({
            back_func = "exit_confirmation",
            no_back = true,
            contents = {
                {
                    n = G.UIT.R,
                    config = { padding = 0, align = "tm"},
                    nodes = {
                        node,
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0.3 },
                            nodes = {
                                is_changed and UIBox_button({
                                    label = { "Load and Save" },
                                    shadow = true,
                                    scale = .45,
                                    colour = G.C.GREEN,
                                    ref_table = profileInfo,
                                    button = "load_modprofile_save",
                                    minh = .6,
                                    minw = 2.5,
                                    col = true
                                }) or nil,
                                ModProfiles.active_profile==nil and UIBox_button({
                                    label = { "Create and Save" },
                                    shadow = true,
                                    scale = .45,
                                    colour = G.C.GREEN,
                                    ref_table = profileInfo,
                                    button = "new_modprofile_ui",
                                    minh = .6,
                                    minw = 2.9,
                                    col = true
                                }) or nil,
                                (is_changed or ModProfiles.active_profile==nil) and UIBox_button({
                                    label = { "Load without saving" },
                                    shadow = true,
                                    scale = .45,
                                    colour = G.C.RED,
                                    ref_table = profileInfo,
                                    button = "load_modprofile",
                                    minh = .6,
                                    minw = 2.9,
                                    col = true
                                }) or nil,
                                (not is_changed and ModProfiles.active_profile) and UIBox_button({
                                    label = { "Confirm" },
                                    shadow = true,
                                    scale = .45,
                                    colour = ModProfiles.active_profile and G.C.GREEN or G.C.RED,
                                    ref_table = profileInfo,
                                    button = "load_modprofile",
                                    minh = .6,
                                    minw = 2.9,
                                    col = true
                                }) or nil,
                                UIBox_button({
                                    label = { "Cancel" },
                                    shadow = true,
                                    scale = .45,
                                    colour = G.C.UI.TEXT_INACTIVE,
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
    })
end
G.FUNCS.load_modprofile_save = function (e)
    local profileInfo = e.config.ref_table
    ModProfiles.deleteProfile(ModProfiles.active_profile)
    ModProfiles.createNewProfile(ModProfiles.active_profile)
    G.FUNCS.load_modprofile(e)
end

G.FUNCS.load_modprofile = function (e)
    local profileInfo = e.config.ref_table
    ModProfiles.loadProfile(profileInfo.name)
    play_sound('crumple1', 0.8, 1);
    --G.FUNCS.exit_confirmation(e)
    G.FUNCS.overlay_menu({
        definition = create_UIBox_generic_options({
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
                                {n=G.UIT.O, config={
                                    object = DynaText({
                                        string = {"Loading profile..."}, 
                                        colours = {G.C.UI.TEXT_LIGHT}, 
                                        shadow = true, 
                                        float = true,
                                        spacing = 1.5,
                                        scale = 0.6,
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
                                        string = {"The game will restart automatically."}, 
                                        colours = {G.C.JOKER_GREY}, 
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

G.FUNCS.new_modprofile_ui = function ()
    local value = {name=""}
    G.FUNCS.overlay_menu({definition = 
    create_UIBox_generic_options({
        back_func = "exit_confirmation",
        no_back = true,
        contents = {
            {n = G.UIT.R, config = { padding = 0, align = "cm" }, nodes = {
                {n=G.UIT.R, config={align = "cm", padding = 0.12, emboss = 0.1, colour =darken( G.C.L_BLACK,.2), r = 0.1}, nodes={
                    {n = G.UIT.T, config = {
                        id="set_profile_text",
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
                            button = "new_modprofile",
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
G.OVERLAY_MENU:get_UIE_by_ID("set_profile_text").UIBox:recalculate()
end
G.FUNCS.new_modprofile = function(args)
    ModProfiles.createNewProfile(args.config.ref_table.name)
    G.FUNCS.overlay_menu({
        definition = create_UIBox_generic_options({
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
                                {n=G.UIT.O, config={
                                    object = DynaText({
                                        string = {"Creating profile..."}, 
                                        colours = {G.C.UI.TEXT_LIGHT}, 
                                        shadow = true, 
                                        float = true,
                                        spacing = 1.5,
                                        scale = 0.6,
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
                                        string = {"The game will restart automatically."}, 
                                        colours = {G.C.JOKER_GREY}, 
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
G.FUNCS.openProfileFolder = function(e)
    local profileInfo = e.config.ref_table
    love.system.openURL(ModProfiles.profiles_dir.."/"..profileInfo.name)
end

G.FUNCS.openProfilesDirectory = function(e)
    love.system.openURL(ModProfiles.profiles_dir)
end


ModProfiles.checkEdits = checkEdits
ModProfiles.UI = {}

ModProfiles.UI.staticModListContent = staticModListContent
ModProfiles.UI.dynamicModListContent = dynamicModListContent


-- watch lua Mods/ModProfiles/ui.lua