local debug = require("debugging")
local grid = require("gridding")
local lobby = require("lobby")
local utils = require("utils")
local shared = require("shared")

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
    shared.fix_structures()
    build_lobby()
    grid.init_hook()
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
    shared.fix_structures{player=player}
    player.teleport({0,0}, get_lobby_surface())
    on_enter_lobby(event)
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
    local player = game.players[event.player_index]
    shared.fix_structures{player=player}
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
    shared.tick()
    grid.tick()
    lobby.tick()
end)

local function begin_new(player)
    local area = grid.create_new()
    grid.display_catching_up_screen(player)
end

script.on_nth_tick(5, function()
end)

script.on_event(defines.events.on_gui_click, function(event)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
    grid.chunk_generated(event)
end)


Controller = {
    grid=grid,
    lobby=lobby,
    utils=utils,
    new=function()
        begin_new(game.player)
    end
}
