local debug = require("debugging")
local grid = require("gridding")

local lobby_name = "lobby"
local get_lobby_surface = function()
  if game.surfaces[lobby_name] then return game.surfaces[lobby_name] end
  local surface = game.create_surface(lobby_name, {width = 1, height = 1})
  surface.set_tiles({{name = "out-of-map", position = {0,0}}})
  return surface
end

local function build_lobby()
    local surface = get_lobby_surface()
    surface.set_tiles({{name = "out-of-map", position = {0,0}}})
end

script.on_init(function()
    global.players = {}
    build_lobby()
end)

local function on_enter_lobby(event)
    local player = game.players[event.player_index]
    if player.character then
        player.character.destroy()
        player.character = nil;
    end
end

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    global.players = global.players or {}
    global.players[event.player_index] = global.players[event.player_index] or {}
    global.players[event.player_index].controls = ""
    player.teleport({0,0}, get_lobby_surface())
    on_enter_lobby(event)
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
    local player = game.players[event.player_index]
    global.players = global.players or {}
    global.players[event.player_index] = global.players[event.player_index] or {}
    if player.surface.name == lobby_name then
        on_enter_lobby(event)
    end
end)

script.on_event(defines.events.on_player_changed_position, function(event)
    local player = game.players[event.player_index]
    if player.surface.name == lobby_name then
        player.teleport({0,0})
    end
end)

script.on_event(defines.events.on_tick, function(event)
    global.players = global.players or {}
    -- move all players on 'nauvis' to 'empty'
    for _, player in pairs(game.players) do
        if player.surface.name == lobby_name then
            player.zoom = 4
        end
        global.players[player.index] = global.players[player.index] or {} -- Safety :P
    end
end)

local function create_lobby_menu(player)
    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="micro_select_world", direction="vertical", caption={"micro.select-factory"}}
    main_frame.style.width = 385
    main_frame.auto_center = true

    local upper_controls = main_frame.add{type="flow", name="upper_control_flow", direction="horizontal"}
    local space = upper_controls.add{type="empty-widget"}
    space.style.horizontally_stretchable = true
    local invite_button = upper_controls.add{type="button", name="micro_view_invites", caption={"micro.view-invites"}}
    invite_button.style.height = 25
    invite_button.style.font = "default-dialog-button"
    invite_button.style.minimal_width = 25
    invite_button.style.natural_width = 25
    invite_button.style.maximal_width = 385
    invite_button.style.padding = {0, 5}
    local new_button = upper_controls.add{type="button", name="micro_new_factory", caption={"micro.new-factory"}, style="confirm_button", tooltip=""}
    new_button.style.height = 25
    new_button.style.minimal_width = 25
    new_button.style.natural_width = 25
    new_button.style.maximal_width = 385
    new_button.style.horizontally_stretchable = false
    new_button.style.padding = {0, 0, 0, 10}

    local listbox = main_frame.add{type="list-box", name="factories", items={}}

    local lower_controls = main_frame.add{type="flow", name="lower_control_flow", direction="horizontal"}
    local space2 = lower_controls.add{type="empty-widget"}
    space2.style.horizontally_stretchable = true
    local delete_button = lower_controls.add{type="button", name="micro_delete_factory", caption={"micro.delete"}, tooltip={"micro.delete-extra"}, style="tool_button_red"}
    delete_button.style.height = 25
    delete_button.style.font = "default-dialog-button"
    delete_button.style.minimal_width = 25
    delete_button.style.natural_width = 25
    delete_button.style.maximal_width = 385
    delete_button.style.padding = {0, 5}
    local play_button = lower_controls.add{type="button", name="micro_launch_factory", caption={"micro.play"}, style="confirm_button", tooltip=""}
    play_button.style.height = 25
    play_button.style.minimal_width = 25
    play_button.style.natural_width = 25
    play_button.style.maximal_width = 385
    play_button.style.horizontally_stretchable = true
    play_button.style.padding = 0

    play_button.enabled = false
    delete_button.enabled = false

    -- fill in the listbox with factories
    global.players[player.index].member_of = global.players[player.index].member_of or {}
    if #global.players[player.index].member_of == 0 then
        listbox.add_item({"micro.not-found"})
    else
        for _, factory_name in pairs(global.players[player.index].member_of) do
            listbox.add_item(factory_name)
        end
    end
    global.players[player.index].controls = "select_world"
    global.players[player.index].control_frame = main_frame
end

script.on_nth_tick(5, function()
    for _, player in pairs(game.players) do
        if player.surface.name == lobby_name then
            if global.players[player.index].controls ~= "select_world" then
                create_lobby_menu(player)
            end
        end
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
end)
