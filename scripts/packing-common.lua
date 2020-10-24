--luacheck: ignore
local Event = require('__stdlib__/stdlib/event/event')
local Inventory = require('__stdlib__/stdlib/entity/inventory')

local enabled = not script.active_mods['packing-tape'] and settings.get_startup('picker-moveable-chests')

local chests = {
    inventory = {['container'] = defines.inventory.chest, ['logistic-container'] = defines.inventory.chest},
    entity = {
        ['car'] = defines.inventory.car_trunk,
        ['spider-vehicle'] = defines.inventory.spider_trunk,
        ['cargo-wagon'] = defines.inventory.cargo_wagon,
        ['artillery-wagon'] = 255
    },
    ammo = {
        ['car'] = defines.inventory.car_ammo,
        ['spider-vehicle'] = defines.inventory.spider_ammo,
        ['artillery-wagon'] = defines.inventory.artillery_wagon_ammo
    },
    fluid = {['fluid-wagon'] = true}
}
