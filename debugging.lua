local exports = {}

commands.add_command(
    "attach_debug",
    {"micro-doc.cmd-attach_debug"},
    function(command_data)
        local player = game.players[command_data.player_index]
        if not player.admin then
            player.print("Error: insufficent permissions.")
            return
        end
        global.debugging = global.debugging or {}
        if global.debugging[player.index] then
            global.debugging[player.index] = nil
            player.print("Detached debugger log.")
            return
        else
            global.debugging[player.index] = true
            player.print("Attached debugger log.")
            return
        end
    end
)

function exports.printDebug(...)
    if not game then return end -- prevent crashing
    global.debugging = global.debugging or {}
    if global.debugging then
        for _, player in pairs(game.players) do
            if global.debugging[player.index] then
                player.print(...)
            end
        end
    end
end

return exports
