local add = require('lib.vector').add
local mult = require('lib.vector').mult
local neg = require('lib.vector').neg
local apos = require('lib.vector').apos

local has_value = require('lib.common').has_value

local map = require('lib.functional').map
local filter = require('lib.functional').filter

script.on_init(function(event)
    global.watchlist = global.watchlist or {}
end)

-- script.on_event(defines.events.on_robot_built_entity, function(event))
    -- local entity = event.created_entity
    -- game.print(entity.name..' '..entity.type)

function unwatch_train(train)
    for _, movers in pairs(train.locomotives) do
        for i, locomotive in ipairs(movers) do
            global.watchlist[locomotive.unit_number] = nil
        end
    end
end

function count_locomotives(train)
    local c = 0
    for _, movers in pairs(train.locomotives) do
        for i, locomotive in ipairs(movers) do
            c = c + 1
        end
    end
    return c
end

function checkup(train)
    if train == nil then return end
    if check_train_deconstructions(train) or count_locomotives(train) == 0 then
        unwatch_train(train)
        return nil
    end
    if check_train_ghost(train) or check_train_request(train) or check_train_upgrades(train) then
        watch_train(train)
    else
        unwatch_train(train)
        -- game.print('Wroooom! Honk Honk!')
        train.manual_mode = false
    end
end

function checkup_watchlist()
    -- game.print(game.tick..' '..game.table_to_json(global.watchlist))
    local trains = {}
    for k, locomotive in pairs(global.watchlist) do
        if locomotive.valid then
            trains[locomotive.train.id] = locomotive.train
        else
            global.watchlist[k] = nil
        end
    end
    for _, train in pairs(trains) do
        checkup(train)
    end
    if table_size(global.watchlist) == 0 then
        -- game.print('removed!')
        script.on_nth_tick(30, nil)
    end
end

function watch_train(train)
    -- game.print('watching')
    for _, movers in pairs(train.locomotives) do
        for i, locomotive in ipairs(movers) do
            global.watchlist[locomotive.unit_number] = locomotive
            -- game.print('added')
            script.on_nth_tick(30, checkup_watchlist)
        end
    end
end

function check_for_ghosts(entity)
    if entity == nil then return false end
    local rect_w = 0.1
    local rect_h = 4
    -- game.print(game.table_to_json({entity.get_radius(), entity.supports_direction, entity.direction, defines.direction.east, defines.direction.west}))
    if has_value({defines.direction.east, defines.direction.west}, entity.direction) then
        local swap = rect_w
        rect_w = rect_h
        rect_h = swap
    elseif not has_value({defines.direction.north, defines.direction.south}, entity.direction) then return true end

    local pos = apos(entity.position)
    -- local col = {r = math.random(), g = math.random(), b = math.random()}
    -- rendering.draw_circle{color=col, width=2, radius=0.5 + math.random()/2, filled=false, target=pos, time_to_live=600, surface=entity.surface, }
    local area = {add(pos, {-rect_w, -rect_h}), add(pos, {rect_w, rect_h})}
    -- rendering.draw_rectangle{color=col, width=2, filled=false, left_top=area[1], right_bottom=area[2], time_to_live=300, surface=entity.surface, }

    local found_ents = entity.surface.find_entities_filtered{area=area}
    local ghost_train_filter = function(w)
        return w.name == 'entity-ghost' and game.entity_prototypes[w.ghost_type] and game.entity_prototypes[w.ghost_type].weight ~= nil
    end
    local ghost_train = filter(found_ents, ghost_train_filter)
    -- game.table_to_json(map(train, function(q)
    --     -- rendering.draw_circle{color=game.players[1].color, width=2, radius=0.2, filled=true, target=q.position, time_to_live=600, surface=entity.surface, }
    --     return {q.name, q.ghost_type}
    -- end))
    return #ghost_train > 0
end

function check_train_ghost(train)
    if train == nil then return false end
    return check_for_ghosts(train.front_rail) or check_for_ghosts(train.back_rail)
end

function check_train_request(train)
    for _, movers in pairs(train.locomotives) do
        for _, locomotive in ipairs(movers) do
            for _, w in pairs(locomotive.surface.find_entities_filtered{position = locomotive.position}) do
                if w.name == 'item-request-proxy' then return true end
            end
        end
    end
    return false
end

function check_train_upgrades(train)
    for i, v in ipairs(train.carriages) do
        if v.to_be_upgraded() then return true end
    end
    return false
end

function check_train_deconstructions(train)
    for i, v in ipairs(train.carriages) do
        if v.to_be_deconstructed() then return true end
    end
    return false
end

script.on_event(defines.events.on_train_created, function(event)
    -- game.print(game.table_to_json(event))
    checkup(event.train)
end)

script.on_load(function(event)
    if global.watchlist and table_size(global.watchlist) > 0 then
        script.on_nth_tick(30, checkup_watchlist)
    end
end)

-- script.on_event(defines.events.on_robot_built_entity, function(event)
--     event.created_entity_name = event.created_entity.name
--     event.stack_name = event.stack.name
--     game.print(game.table_to_json(event))
-- end)