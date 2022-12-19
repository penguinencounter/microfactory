local exports = {}

local factory_grid_conf = {
    name = "micro",
    chunk_fill_tile = "out-of-map"
}

function init_hook()
end

function chunk_generated(ev)
    if ev.surface.name == factory_grid_conf.name then
        local from, to = ev.area.left_top, ev.area.right_bottom
        local surface = ev.surface
        local tile = factory_grid_conf.chunk_fill_tile
        local update_batch = {}
        for x = from.x, to.x do
            for y = from.y, to.y do
                table.insert(update_batch, {name = tile, position = {x, y}})
            end
        end
        surface.set_tiles(update_batch)
    end
end

return exports