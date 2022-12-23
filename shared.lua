local exports = {}

function exports.fix_structures(options)
    global.players = global.players or {}
    options = options or {}  -- defaults
    if game then
        local function fix_player(player)
            global.players[player.index] = global.players[player.index] or {}
            global.players[player.index].guis = global.players[player.index].guis or {}
        end

        if options.player then
            fix_player(options.player)
        else
            for _, player in pairs(game.players) do
                fix_player(player)
            end
        end
    end

    global.close_screen_jobs = global.close_screen_jobs or {}
end

function exports.register_screen_opened(player_index, interface)
    global.players[player_index].guis[interface.name] = interface
end

function exports.get_screen(player_index, screen_name)
    local player = game.players[player_index]
    return global.players[player.index].guis[screen_name]
end

function exports.close_screen(player_index, screen_name)
    exports.fix_structures()
    if player_index == nil then
        for _, player in pairs(game.players) do
            exports.close_screen(player.index, screen_name)
        end
        return
    end
    local player = game.players[player_index]
    local screen = global.players[player.index].guis[screen_name]
    if screen then
        table.insert(global.close_screen_jobs, {player_index=player_index, screen_name=screen_name})
    end
end

function exports.tick()
    exports.fix_structures()
    for _, job in ipairs(global.close_screen_jobs) do
        local player = game.players[job.player_index]
        local screen = global.players[player.index].guis[job.screen_name]
        if screen then
            screen.destroy()
            global.players[player.index].guis[job.screen_name] = nil
        end
    end
    global.close_screen_jobs = {}
end

return exports