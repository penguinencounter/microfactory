local debugger = require("debugging")
local utils = require("utils")
local shared = require("shared")

local exports = {}

local factory_grid_conf = {
    name = "micro",
    chunk_fill_tile = "out-of-map",
    map_config = {
        property_expression_names = {}  -- Will be filled later in the file
    },
    max_factory_size = 128,
    starting_factory_size = 32
}

factory_grid_conf.map_config.property_expression_names['enemy-base-frequency'] = '0'  -- no biters
factory_grid_conf.map_config.property_expression_names['cliffiness'] = '0'  -- no cliffs


local function get_corner(index)
    --[[
      ...   0
      16 5  | 6  7
      15 4  | 1  8
      ------+----- 0
      14 3  | 2  9
      13 12 | 11 10

      Spiral pattern (clockwise, continues)
    ]]--
    local actual_size = factory_grid_conf.max_factory_size + 8

    local side = 1
    local progress1 = 1
    local progress2 = 0

    local cursor_direction = {x = -1, y = 0}
    local cursor_position = {x = 0, y = 0}

    for _ = 1, index do
        -- move
        cursor_position.x = cursor_position.x + cursor_direction.x
        cursor_position.y = cursor_position.y + cursor_direction.y

        progress1 = progress1 - 1

        if progress1 == 0 then -- turn right
            cursor_direction = {x = cursor_direction.y, y = -cursor_direction.x}

            progress2 = progress2 + 1
            if progress2 == 2 then
                progress2 = 0
                side = side + 1
            end
            progress1 = side
        end
    end
    cursor_position.x = cursor_position.x * actual_size
    cursor_position.y = cursor_position.y * actual_size
    return cursor_position
end


local function fix_structures()
    global.grid = global.grid or {}
    global.grid.surface_ok = global.grid.surface_ok or false
    global.grid.new_factory_queue = global.grid.new_factory_queue or {}
    global.grid.new_factory_queue.last_count = global.grid.new_factory_queue.last_count or 0
    global.grid.new_factory_queue.start = global.grid.new_factory_queue.start or {}
    global.grid.new_factory_queue.chunk_queue = global.grid.new_factory_queue.chunk_queue or {}
    global.grid.next_factory = global.grid.next_factory or 0
    global.grid.the_letter_H = global.grid.the_letter_H or 0
end


function exports.init_hook()
    fix_structures()
end

local function update_waiting_screens()
    fix_structures()
    shared.fix_structures()
    local total_to_do = #global.grid.new_factory_queue.chunk_queue
    for _, player in pairs(game.players) do
        local screen = shared.get_screen(player.index, "micro_catching_up")
        if screen then
            local total = global.grid.new_factory_queue.last_count
            local done = total - total_to_do
            local percent = done / total
            if percent ~= percent or percent > 1 or percent < 0 then
                percent = 0
            end
            screen.progress_bar.value = percent
            local percent_str = utils.format_digits(utils.round(percent * 100, 1), 1)
            screen.flow.progress_counter_label.caption = {"micro.out-of", done, total}
            screen.flow.progress_percentage_label.caption = {"micro.percentage", percent_str}
        end
    end
end

function exports.tick()
    fix_structures()
    if not global.grid.surface_ok then
        game.create_surface(factory_grid_conf.name, factory_grid_conf.map_config)
        if game.surfaces[factory_grid_conf.name] then
            game.surfaces[factory_grid_conf.name].always_day = true
            global.grid.surface_ok = true
        end
    else
        update_waiting_screens()
    end
    if #global.grid.new_factory_queue.start > 0 then
        local idx = table.remove(global.grid.new_factory_queue.start, 1)
        local corner = get_corner(idx)
        local surface = game.surfaces[factory_grid_conf.name]
        local size = factory_grid_conf.starting_factory_size + 8
        local from = {x = corner.x, y = corner.y}
        local to = {x = corner.x + size, y = corner.y + size}

        local start_chnk = {x = math.floor(from.x / 32), y = math.floor(from.y / 32)}
        local end_chnk = {x = math.ceil(to.x / 32), y = math.ceil(to.y / 32)}

        for x = start_chnk.x, end_chnk.x do
            for y = start_chnk.y, end_chnk.y do
                if not surface.is_chunk_generated({x, y}) then
                    surface.request_to_generate_chunks({x * 32, y * 32}, 1)
                    table.insert(global.grid.new_factory_queue.chunk_queue, {x, y})
                    global.grid.new_factory_queue.last_count = global.grid.new_factory_queue.last_count + 1
                end
            end
        end
    end
end

function exports.chunk_generated(ev)
    if ev.surface.name == factory_grid_conf.name then
        local from, to = ev.area.left_top, ev.area.right_bottom
        local surface = ev.surface
        local update_batch = {}
        debugger.printDebug("Chunk generated: " .. ev.position.x .. ", " .. ev.position.y)
        for x = from.x, to.x do
            for y = from.y, to.y do
                table.insert(update_batch, {name = factory_grid_conf.chunk_fill_tile, position = {x, y}})
            end
        end
        local entity_count = 0
        for _, entity in pairs(surface.find_entities_filtered{area = ev.area}) do
            entity_count = entity_count + 1
            entity.destroy()
        end
        debugger.printDebug("-> Entities destroyed: " .. entity_count)
        surface.set_tiles(update_batch)
        for pos, v in ipairs(global.grid.new_factory_queue.chunk_queue) do
            if utils.match_pos(v, ev.position) then
                debugger.printDebug("-> Matching item in queue; " .. #global.grid.new_factory_queue.chunk_queue - 1 .. " items left")
                table.remove(global.grid.new_factory_queue.chunk_queue, pos)
                if #global.grid.new_factory_queue.chunk_queue == 0 then
                    global.grid.new_factory_queue.last_count = 0
                    shared.close_screen(nil, "micro_catching_up")  -- all
                end
                break
            end
        end
    end
end

function exports.create_new(owner)
    fix_structures()
    local idx = global.grid.next_factory
    global.grid.next_factory = idx + 1
    table.insert(global.grid.new_factory_queue.start, idx)
    return idx
end

function exports.build(n)
    local corner = get_corner(n)
    local offset = 4 + (factory_grid_conf.max_factory_size - factory_grid_conf.starting_factory_size)
end

function exports.display_catching_up_screen(player)
    shared.fix_structures{player=player}
    local gui = player.gui.center
    shared.close_screen(player.index, "micro_catching_up")
    local frame = gui.add{type = "frame", name = "micro_catching_up", direction = "vertical", caption = {"micro.catching-up"}}
    frame.style.width = 360
    local progress = frame.add{type = "progressbar", name = "progress_bar"}
    local flow = frame.add{type = "flow", name="flow", direction = "horizontal"}
    flow.style.horizontally_stretchable = true
    flow.add{type = "label", name = "progress_counter_label", caption = {"micro.out-of", "?", "?"}}
    local hpush = flow.add{type = "empty-widget"}
    hpush.style.horizontally_stretchable = true
    flow.add{type = "label", name = "progress_percentage_label", caption = {"micro.percentage", "0.0"}}
    progress.style.horizontally_stretchable = true
    shared.register_screen_opened(player.index, frame)
end

return exports