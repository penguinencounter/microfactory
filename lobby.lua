local exports = {}


local function fix_structures()
    global.lobby = global.lobby or {}
    global.lobby.surface_ok = global.lobby.surface_ok or false
end


function exports.tick()
    fix_structures()
    if not global.lobby.surface_ok then
        if game.surfaces["lobby"] then
            game.surfaces["lobby"].set_tiles({{name = "out-of-map", position = {0,0}}})
            global.lobby.surface_ok = true
        else
            game.create_surface("lobby", {width = 1, height = 1})
            if game.surfaces["lobby"] then
                game.surfaces["lobby"].set_tiles({{name = "out-of-map", position = {0,0}}})
                global.lobby.surface_ok = true
            end
        end
    end
end

function exports.chunk_generated(ev)
    if ev.surface.name ~= "lobby" then
        return
    end
    ev.surface.set_tiles({{name = "out-of-map", position = {0,0}}})
end

return exports
