local debugger = require("debugging")

local exports = {}

local factory_grid_conf = {
    name = "micro",
    chunk_fill_tile = "out-of-map",
    map_config = {
        property_expression_names = {}  -- Will be filled later in the file
    }
}

factory_grid_conf.map_config.property_expression_names['enemy-base-frequency'] = '0'  -- no biters
factory_grid_conf.map_config.property_expression_names['cliffiness'] = '0'  -- no cliffs


function exports.init_hook()
    game.create_surface(factory_grid_conf.name, factory_grid_conf.map_config)
end

function exports.chunk_generated(ev)
    if ev.surface.name == factory_grid_conf.name then
        local from, to = ev.area.left_top, ev.area.right_bottom
        local surface = ev.surface
        local update_batch = {}
        debugger.printDebug("Chunk generated: " .. from.x .. ", " .. from.y .. " to " .. to.x .. ", " .. to.y)
        for x = from.x, to.x do
            for y = from.y, to.y do
                table.insert(update_batch, {name = factory_grid_conf.chunk_fill_tile, position = {x, y}})
            end
        end
        for _, entity in pairs(surface.find_entities_filtered{area = ev.area}) do
            debugger.printDebug("Chunk generated: Removing entity: " .. entity.name .. " at " .. entity.position.x .. ", " .. entity.position.y)
            entity.destroy()
        end
        surface.set_tiles(update_batch)
    end
end

return exports