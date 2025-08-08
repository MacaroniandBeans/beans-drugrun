local spawnedPed = nil
local pedModel = Config.StartPed.model
local pedCoords = Config.StartPed.coords
local pedRadius = 40.0
local interactionAdded = false

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - pedCoords.xyz)

        if distance < pedRadius then
            if not spawnedPed then
                lib.requestModel(pedModel)
                spawnedPed = CreatePed(0, pedModel, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
                FreezeEntityPosition(spawnedPed, true)
                SetEntityInvincible(spawnedPed, true)
                SetBlockingOfNonTemporaryEvents(spawnedPed, true)

                if not interactionAdded then
                    exports.ox_target:addLocalEntity(spawnedPed, {
                        {
                            icon = "fas fa-box",
                            label = "Deposit Drugs",
                            onSelect = function()
                                exports.ox_inventory:openInventory('stash', {
                                    id = 'drugplane_drop',
                                    label = 'Drug Plane Drop Stash',
                                    slots = Config.StashSize.slots,
                                    weight = Config.StashSize.weight
                                })
                            end
                        },
                        {
                            icon = "fas fa-plane",
                            label = "Start Plane Run",
                            onSelect = function()
                                local stashId = 'drugplane_drop'
                                lib.callback('beans-drugplane:getStashItems', false, function(items)
                                    if not items or #items == 0 then
                                        return lib.notify({ type = 'error', description = 'No drugs in stash!' })
                                    end

                                    local runItems = {}
                                    local totalCount = 0

                                    for _, item in pairs(items) do
                                        for _, allowed in pairs(Config.AllowedDrugs or {}) do
                                            if item.name == allowed then
                                                runItems[#runItems+1] = {
                                                    name = item.name,
                                                    count = item.count,
                                                    purity = tonumber((item.metadata and item.metadata.purity) or 50)
                                                }
                                                totalCount += item.count
                                            end
                                        end
                                    end

                                    if totalCount < (Config.RequiredAmount or 1) then
                                        return lib.notify({
                                            type = 'error',
                                            description = ('You need at least %d valid bricks.'):format(Config.RequiredAmount or 1)
                                        })
                                    end

                                    TriggerServerEvent("beans-drugplane:startRun", runItems)
                                end, stashId)
                            end
                        }
                    })

                    interactionAdded = true
                end
            end
        elseif spawnedPed then
            DeleteEntity(spawnedPed)
            spawnedPed = nil
            interactionAdded = false
        end

        Wait(1000)
    end
end)

RegisterNetEvent('beans-drugplane:startRun', function()
    lib.requestModel(Config.PlaneModel)

    local plane = CreateVehicle(Config.PlaneModel, Config.SpawnPlane.xyz, Config.SpawnPlane.w, true, false)
    SetEntityAsMissionEntity(plane, true, true)

    SetVehicleDoorsLocked(plane, 1)
    SetVehicleDoorsLockedForAllPlayers(plane, false)
    SetVehicleDoorsLockedForPlayer(plane, PlayerId(), false)

    local plate = GetVehicleNumberPlateText(plane)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TaskWarpPedIntoVehicle(PlayerPedId(), plane, -1)

    local dropZones = {}
    local dropCount = math.random(Config.DropCountRange.min, Config.DropCountRange.max)
    local pool = table.clone(Config.DropLocations)
    lib.table.shuffle(pool)

    for i = 1, dropCount do
        dropZones[#dropZones+1] = pool[i]
    end

    TriggerEvent('beans-drugplane:handleFlightPath', plane, dropZones)
end)

RegisterNetEvent('beans-drugplane:handleFlightPath', function(plane, dropZones)
    local current = 1
    local total = #dropZones
    local dropping = false
    local runComplete = false

    local blip = AddBlipForCoord(dropZones[current])
    SetBlipRoute(blip, true)

    CreateThread(function()
        while current <= total do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - dropZones[current])

            if dist < 100.0 and not dropping then
                dropping = true
                lib.notify({ description = 'Dropping package...', type = 'success' })

                local planeCoords = GetEntityCoords(plane)
                local dropZ = planeCoords.z - 5.0

                local dropObj = CreateObject(`prop_coke_block_01`, planeCoords.x, planeCoords.y, dropZ, true, true, true)
                SetEntityVelocity(dropObj, 0.0, 0.0, -5.0)
                Wait(2000)

                RemoveBlip(blip)
                current += 1
                if dropZones[current] then
                    blip = AddBlipForCoord(dropZones[current])
                    SetBlipRoute(blip, true)
                else
                    lib.notify({ description = 'Final drop complete. Return to airstrip!', type = 'inform' })
                    runComplete = true
                    SetNewWaypoint(Config.LandingZone.x, Config.LandingZone.y)
                end
                dropping = false
            end
            Wait(500)
        end

        -- Wait for return
        CreateThread(function()
            while true do
                local dist = #(GetEntityCoords(PlayerPedId()) - Config.LandingZone)
                if runComplete and dist < 50.0 then
                    lib.notify({ description = 'Drop-off complete. Run finished.', type = 'success' })
                    TriggerServerEvent('beans-drugplane:completeRun')
                    DeleteVehicle(plane)
                    break
                end
                Wait(1000)
            end
        end)
    end)
end)
