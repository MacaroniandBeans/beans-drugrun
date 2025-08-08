print("✅ [DrugPlane] server.lua loaded")

local ActiveRuns = {}

-- 🧱 Shared stash registration
local function registerDrugPlaneStash()
    exports.ox_inventory:RegisterStash(
        'drugplane_drop',
        'Drug Plane Drop Stash',
        Config.StashSize.slots,
        Config.StashSize.weight,
        nil -- shared stash (no owner)
    )
    print("✅ [DrugPlane] Shared stash 'drugplane_drop' registered.")
end

-- 🔁 Re-register stash on resource restart
AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' or resource == GetCurrentResourceName() then
        Wait(500)
        registerDrugPlaneStash()
    end
end)

-- 📦 Fetch stash items for client validation
lib.callback.register('beans-drugplane:getStashItems', function(source, stashId)
    local inventory = exports.ox_inventory:GetInventory(stashId)

    if not inventory or not inventory.items then
        print(('[DrugPlane] Items in stash %s: false'):format(stashId))
        return false
    end

    print(('[DrugPlane] Items in stash %s: %s items'):format(stashId, #inventory.items))
    return inventory.items
end)

-- 🚀 Start the drug plane run
RegisterNetEvent("beans-drugplane:startRun", function(runItems)
    local src = source
    local stashId = 'drugplane_drop'

    if ActiveRuns[src] then
        return TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'You already started a run!'
        })
    end

    if not runItems or #runItems == 0 then
        return TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'No valid items provided.'
        })
    end

    local itemsToDelete, storedItems = {}, {}
    local inventory = exports.ox_inventory:GetInventory(stashId)
    local stash = inventory and inventory.items

    if type(stash) ~= "table" then
        return TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Stash is empty or unavailable.'
        })
    end

    for _, item in pairs(stash) do
        for _, input in pairs(runItems) do
            if item.name == input.name and item.count == input.count then
                storedItems[#storedItems+1] = {
                    name = item.name,
                    count = item.count,
                    metadata = item.metadata or {}
                }
                itemsToDelete[#itemsToDelete+1] = {
                    name = item.name,
                    count = item.count,
                    slot = item.slot
                }
            end
        end
    end

    if #storedItems == 0 then
        return TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Run items not found in stash.'
        })
    end

    for _, del in ipairs(itemsToDelete) do
        exports.ox_inventory:RemoveItem("stash", stashId, del.name, del.count, del.slot)
    end

    -- ✅ Final clean-up to remove leftovers
    exports.ox_inventory:ClearInventory("stash", stashId, false)
    print(('🧹 [DrugPlane] Cleared stash after run start: %s'):format(stashId))

    ActiveRuns[src] = storedItems
    TriggerClientEvent("beans-drugplane:startRun", src)
end)

-- 💰 Complete run & payout
RegisterNetEvent("beans-drugplane:completeRun", function()
    local src = source
    local items = ActiveRuns[src]
    if not items then return end

    local total = 0
    for _, item in pairs(items) do
        local purity = tonumber(item.metadata and item.metadata.purity) or 50
        local payout = purity * Config.PayoutPerPurity * item.count
        total += payout
        print(("[DrugPlane] %s x%d | Purity: %d%% | Payout: $%d"):format(item.name, item.count, purity, payout))
    end

    ActiveRuns[src] = nil
    exports.ox_inventory:AddItem(src, 'money', total)

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('You earned $%d for the drop.'):format(total)
    })

    -- 🧹 Optional safety clear
    exports.ox_inventory:ClearInventory("stash", 'drugplane_drop', false)
    print("[DrugPlane] Final stash wipe after run.")
end)

-- 🧪 Admin command to give coke bricks
RegisterCommand('givecoke', function(source, args)
    local target = tonumber(args[1]) or source
    local count = tonumber(args[2]) or 1
    local purity = tonumber(args[3]) or 50

    local success = exports.ox_inventory:AddItem(target, 'coke_batch', count, { purity = purity })

    if success then
        print(("[DrugPlane] Gave %d coke bricks with %d%% purity to player %d"):format(count, purity, target))
    else
        print(("❌ Failed to give item to player %d"):format(target))
    end
end, true)


RegisterCommand('cleardrugstash', function(source)
    local src = source
    local stashId = 'drugplane_drop'

    local inventory = exports.ox_inventory:GetInventory(stashId)

    if inventory and inventory.items then
        for _, item in pairs(inventory.items) do
            exports.ox_inventory:RemoveItem('stash', stashId, item.name, item.count, item.slot)
        end
        print(('🧹 [DrugPlane] Removed all items from stash: %s'):format(stashId))
    else
        print(('ℹ️ [DrugPlane] No items found in stash: %s'):format(stashId))
    end

    -- Force refresh for all players (optional)
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('ox_inventory:forceCloseInventory', playerId)
    end
end, true)
