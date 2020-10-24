--luacheck: ignore

do -- Saving Code
    -- Save item-with-inventory-data
    -- These are handled by replacing the normal item in the mined buffer
    local function save_inventory_data(chest)
        local item_name = 'picker-moveable-' .. chest.name
        if not game.item_prototypes[item_name] then return end

        local source = chest.get_inventory(types.inventory[chest.type])
        if source.is_empty() and not source.is_filtered() then return end

        local data = {type = 'inventory', inventories = {}}
        data.inventories.main = game.create_inventory(1)

        local stack = data.inventories.main[1]
        stack.set_stack(item_name)
        stack.health = chest.get_health_ratio()

        local dest = stack.get_inventory(defines.inventory.item_main)
        Inventory.transfer_inventory(source, dest)
        local prototype = chest.prototype

        data.bar = source.supports_bar() and source.get_bar()
        data.storage_filter = prototype.logistic_mode == 'storage' and chest.storage_filter
        local requester = prototype.logistic_mode == 'requester' or prototype.logistic_mode == 'buffer'
        if requester then
            data.request_slots = {}
            for i = 1, chest.request_slot_count do data.request_slots[i] = chest.get_request_slot(i) end
            data.request_from_buffers = chest.request_from_buffers
        end
        global.awaiting = {type = data.type, entity = chest, data = data}
    end

    -- Save item-with-entity data
    -- preserves Grids/etc
    local function save_car_data(car)
        local data = {type = 'entity', inventories = {}}
        local main_inv = car.get_inventory(types.entity[car.type])
        if main_inv and (not main_inv.is_empty() or main_inv.is_filtered()) then
            data.inventories.main = game.create_inventory(#main_inv)
            data.main_filters = Inventory.transfer_inventory(main_inv, data.inventories.main)
        end

        local ammo_define = types.ammo[car.type]
        local ammo_inv = ammo_define and car.get_inventory(ammo_define)
        if ammo_inv and (not ammo_inv.is_empty() or ammo_inv.is_filtered()) then
            if car.type == 'artillery-wagon' then
                data.inventories.ammo = game.create_inventory(ammo_inv[1].count)
                data.inventories.ammo.insert(ammo_inv[1])
                ammo_inv.clear()
                data.ammo_filters = ammo_inv.is_filtered() and ammo_inv.get_filter(1)
            else
                data.inventories.ammo = game.create_inventory(#ammo_inv)
                data.ammo_filters = Inventory.transfer_inventory(ammo_inv, data.inventories.ammo)
            end
        end

        local fuel_inv = car.get_fuel_inventory()
        if fuel_inv and not fuel_inv.is_empty() then
            data.inventories.fuel = game.create_inventory(#fuel_inv)
            Inventory.transfer_inventory(fuel_inv, data.inventories.fuel)
        end

        --Spider-ammo?
        --Artillery-ammo?

        local burner = car.burner
        if burner then
            data.currently_burning = burner.currently_burning
            data.remaining_burning_fuel = burner.remaining_burning_fuel
            burner.currently_burning = nil
            burner.remaining_burning_fuel = 0
        end

        global.awaiting = {type = data.type, entity = car, data = data}
    end

    local function save_fluid_data(entity)
        local boxes = entity.fluidbox
        if boxes then
            local data = {type = 'fluid', boxes = {}}
            for i = 1, #boxes do data.boxes[i] = boxes[i] end
            global.awaiting = {type = data.type, entity = entity, data = data}
        end
    end

    -- Move the contents from the chest into an item in our inventory
    local function entity_to_inventory(event)
        local chest = event.entity

        if not container_types[chest.type] then return end

        local player = game.get_player(event.player_index)
        if not player.get_main_inventory().find_empty_stack() then return end

        if types.inventory[chest.type] then
            save_inventory_data(chest)
        elseif types.entity[chest.type] then
            save_car_data(chest)
        elseif types.fluid[chest.type] then
            save_fluid_data(chest)
        end
    end
    Event.register_if(enabled, defines.events.on_pre_player_mined_item, entity_to_inventory)

    local function awaiting_mined_entity(event)
        if not global.awaiting then return end

        if event.entity ~= global.awaiting.entity then return __DebugAdapter.breakpoint() end

        local prototype = event.entity.prototype

        local products = prototype.mineable_properties.products
        if not products then return __DebugAdapter.breakpoint() end

        local stack
        for _, product in ipairs(products) do
            if product.type == 'item' then
                stack = event.buffer.find_item_stack(product.name)
                if stack then break end
            end
        end

        if global.awaiting.type == 'inventory' then
            if not (stack and stack.valid_for_read) then return __DebugAdapter.breakpoint() end
            local inv = global.awaiting.data.inventories.main
            if not stack.set_stack(inv[1]) then return __DebugAdapter.breakpoint() end
            inv.destroy()
        end

        if not (stack and stack.valid_for_read) then return __DebugAdapter.breakpoint() end

        global.inventory_chest = global.inventory_chest or {}
        global.inventory_chest[stack.item_number] = global.awaiting.data
        global.awaiting = nil
    end
    Event.register_if(enabled, defines.events.on_player_mined_entity, awaiting_mined_entity)
end

Event.on_init_if(enabled, function()
    global.inventory_chest = {}
end)
