--luacheck: ignore
do -- Loading code
    local function load_car_data(car, data)
        local cargo_inv = data.cargo_inv and data.cargo_inv.valid
        local burner = car.burner
        if burner then
            burner.currently_burning = data.currently_burning
            burner.remaining_burning_fuel = data.remaining_burning_fuel or 0
        end
        if data.fuel_inv and data.fuel_inv.valid then
            local fuel_inv = car.get_fuel_inventory
            if fuel_inv then
                Inventory.transfer_inventory(data.fuel_inv, fuel_inv)
                data.fuel_inv.destroy()
            end
        end
        if data.ammo_inv and data.ammo_inv.valid then
            local ammo_inv = car.get_inventory(defines.inventory.car_ammo)
            if ammo_inv then
                Inventory.transfer_inventory(data.ammo_inv, ammo_inv, data.ammo_filters)
                data.ammo_inv.destroy()
            end
        end
    end

    local function inventory_to_entity(event)
        local stack = event.stack
        local chest = event.created_entity

        if not (stack and stack.valid_for_read and stack.item_number) then return end
        global.inventory_chest = global.inventory_chest or {}
        local data = global.inventory_chest[stack.item_number]
        if not data then return end
        global.inventory_chest[stack.item_number] = nil
        __DebugAdapter.print('nilling')
        do return end

        if types.inventory[chest.type] then
            load_inventory_data()
        elseif types.entity[chest.type] then
            load_entity_data()
        elseif types.fluid[chest.type] then
            local_fluid_data()
        end

        if chest_types[chest.type] and stack and stack.valid_for_read and stack.name:find('^picker%-moveable%-') then
            if data then
                local source = event.stack.get_inventory(defines.inventory.item_main)
                local destination = chest.get_inventory(chest_types[chest.type])
                Inventory.transfer_inventory(source, destination)

                if chest.type == 'car' then
                    retrieve_car_data(chest, data)
                else
                    if data.bar then destination.set_bar(data.bar) end
                    local proto = chest.prototype
                    if proto.logistic_mode == 'storage' then
                        chest.storage_filter = data.storage_filter
                    elseif proto.logistic_mode == 'requester' or proto.logistic_mode == 'buffer' then
                        for slot, filter in pairs(data.request_slots or {}) do
                            chest.set_request_slot(filter, slot)
                        end
                        chest.request_from_buffers = data.request_from_buffers
                    end
                end
            end
            global.inventory_chest[stack.item_number] = nil
        end
    end
    -- Event.register_if(enabled, defines.events.on_built_entity, inventory_to_entity)
end
