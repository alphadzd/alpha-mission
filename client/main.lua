local QBCore = exports['qb-core']:GetCoreObject()
local npcPed = nil
local npcSpawned = false
local npcBlip = nil
local deliveryNPC = nil
local deliveryBlip = nil
local enemyPeds = {}
local enemyVehicles = {}
local missionActive = false
local missionStage = 0
local missionCooldown = false
local cooldownTimer = 0
local selectedLocation = nil
local teamMembers = {}


local function StartMissionCooldown()
    missionCooldown = true
    cooldownTimer = Config.MissionCooldown
    
    CreateThread(function()
        while cooldownTimer > 0 and missionCooldown do
            cooldownTimer = cooldownTimer - 1
            Wait(1000)
        end
        missionCooldown = false
    end)
end

local function CleanupMission()
    
    if deliveryNPC then
        DeleteEntity(deliveryNPC)
        deliveryNPC = nil
    end
    
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    
    for _, ped in ipairs(enemyPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    enemyPeds = {}
    
    for _, vehicle in ipairs(enemyVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    enemyVehicles = {}
    
    
    missionActive = false
    missionStage = 0
    selectedLocation = nil
    
    
    TriggerServerEvent('alpha-mission:server:notifyTeam', 'Mission cleanup completed')
end

local function CreateDeliveryNPC()
    if not selectedLocation then
        selectedLocation = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
    end
    
    local model = GetHashKey(Config.DeliveryNPCModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    deliveryNPC = CreatePed(4, model, selectedLocation.x, selectedLocation.y, selectedLocation.z - 1.0, selectedLocation.w, false, true)
    
    FreezeEntityPosition(deliveryNPC, true)
    SetEntityInvincible(deliveryNPC, true)
    SetBlockingOfNonTemporaryEvents(deliveryNPC, true)
    
    TaskStartScenarioInPlace(deliveryNPC, Config.DeliveryNPCScenario, 0, true)
    
    deliveryBlip = AddBlipForCoord(selectedLocation.x, selectedLocation.y, selectedLocation.z)
    SetBlipSprite(deliveryBlip, 501)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.8)
    SetBlipColour(deliveryBlip, 5)
    SetBlipAsShortRange(deliveryBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(deliveryBlip)
    SetBlipRoute(deliveryBlip, true)
    
    
    if Config.UseTarget and exports['qb-target'] then
        exports['qb-target']:AddTargetEntity(deliveryNPC, {
            options = {
                {
                    icon = "fas fa-briefcase",
                    label = "Deliver Package",
                    action = function()
                        TriggerEvent('alpha-mission:client:deliverPackage')
                    end,
                    canInteract = function()
                        return missionActive and missionStage == 1
                    end
                },
            },
            distance = 2.0,
        })
    end
    
    return true
end

local function SpawnEnemyVehicles()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for i = 1, Config.EnemyCarsCount do
        local vehicleModel = Config.EnemyVehicles[math.random(#Config.EnemyVehicles)]
        local hash = GetHashKey(vehicleModel)
        
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(0)
        end
        
        local spawnDistance = math.random(50, 100) + 0.0
        local spawnAngle = math.random(0, 359) + 0.0
        local spawnX = playerCoords.x + (math.cos(math.rad(spawnAngle)) * spawnDistance)
        local spawnY = playerCoords.y + (math.sin(math.rad(spawnAngle)) * spawnDistance)
        
        local groundZ = 0
        local ground, posZ = GetGroundZFor_3dCoord(spawnX, spawnY, 100.0, 0)
        if ground then
            groundZ = posZ
        else
            groundZ = playerCoords.z
        end
        
        local vehicle = CreateVehicle(hash, spawnX, spawnY, groundZ, spawnAngle, true, false)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleDoorsLocked(vehicle, 2)
        
        for j = 1, Config.EnemiesPerCar do
            local pedModel = Config.EnemyPeds[math.random(#Config.EnemyPeds)]
            local pedHash = GetHashKey(pedModel)
            
            RequestModel(pedHash)
            while not HasModelLoaded(pedHash) do
                Wait(0)
            end
            
            local ped = CreatePedInsideVehicle(vehicle, 4, pedHash, j-2, true, false)
            
            GiveWeaponToPed(ped, GetHashKey(Config.EnemyWeapon), 500, false, true)
            SetCurrentPedWeapon(ped, GetHashKey(Config.EnemyWeapon), true)
            
            SetEntityAsMissionEntity(ped, true, true)
            
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatAttributes(ped, 5, true)
            SetPedCombatAttributes(ped, 0, true)
            
            SetPedRelationshipGroupHash(ped, GetHashKey("HATES_PLAYER"))
            
            SetPedAccuracy(ped, Config.EnemyWeaponAccuracy)
            SetPedArmour(ped, Config.EnemyArmor)
            
            local health = 100
            if Config.EnemyDifficulty == 1 then
                health = 100
            elseif Config.EnemyDifficulty == 2 then
                health = 150
            elseif Config.EnemyDifficulty == 3 then
                health = 200
            end
            
            SetEntityHealth(ped, health)
            
            if Config.EnemyDifficulty == 3 then
                SetPedCombatMovement(ped, 3)
                SetPedCombatRange(ped, 2)
                SetPedCombatAbility(ped, 100)
            elseif Config.EnemyDifficulty == 2 then
                SetPedCombatMovement(ped, 2)
                SetPedCombatRange(ped, 1)
                SetPedCombatAbility(ped, 75)
            else
                SetPedCombatMovement(ped, 1)
                SetPedCombatRange(ped, 0)
                SetPedCombatAbility(ped, 50)
            end
            
            table.insert(enemyPeds, ped)
        end
        
        table.insert(enemyVehicles, vehicle)
        
        local driver = GetPedInVehicleSeat(vehicle, -1)
        
        local drivingStyle = 786603
        if Config.EnemyDifficulty == 3 then
            drivingStyle = 1074528293
        elseif Config.EnemyDifficulty == 2 then
            drivingStyle = 786603
        else
            drivingStyle = 443
        end
        
        local speed = 60.0
        if Config.EnemyDifficulty == 3 then
            speed = 80.0
        elseif Config.EnemyDifficulty == 2 then
            speed = 60.0
        else
            speed = 40.0
        end
        
        TaskVehicleDriveToCoord(driver, vehicle, playerCoords.x, playerCoords.y, playerCoords.z, speed, 1.0, hash, drivingStyle, 5.0, true)
        
        for _, ped in ipairs(enemyPeds) do
            TaskCombatPed(ped, playerPed, 0, 16)
        end
    end
    
    SetRelationshipBetweenGroups(5, GetHashKey("HATES_PLAYER"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("HATES_PLAYER"))
    
    QBCore.Functions.Notify("Enemy vehicles approaching! Enemies: " .. (Config.EnemyCarsCount * Config.EnemiesPerCar), "error", 5000)
    
    return true
end

local function CheckAllEnemiesDead()
    local allDead = true
    
    for _, ped in ipairs(enemyPeds) do
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            allDead = false
            break
        end
    end
    
    return allDead
end

local function CreateNPCBlip()
    if not Config.EnableBlip then return end
    
    npcBlip = AddBlipForCoord(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
    SetBlipSprite(npcBlip, Config.BlipSprite)
    SetBlipDisplay(npcBlip, 4)
    SetBlipScale(npcBlip, Config.BlipScale)
    SetBlipColour(npcBlip, Config.BlipColor)
    SetBlipAsShortRange(npcBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.BlipName)
    EndTextCommandSetBlipName(npcBlip)
end

local function RemoveNPCBlip()
    if npcBlip then
        RemoveBlip(npcBlip)
        npcBlip = nil
    end
end

local function SetupTarget()
    if not Config.UseTarget or not Config.EnableInteraction then return end
    
    if exports['qb-target'] then
        exports['qb-target']:AddTargetEntity(npcPed, {
            options = {
                {
                    icon = Config.TargetIcon,
                    label = Config.TargetLabel,
                    action = function()
                        TriggerEvent('alpha-mission:client:interactWithNPC')
                    end,
                },
                {
                    icon = "fas fa-check-circle",
                    label = "Complete Mission",
                    action = function()
                        TriggerEvent('alpha-mission:client:completeMission')
                    end,
                    canInteract = function()
                        return missionActive and missionStage == 3
                    end
                },
            },
            distance = 2.0,
        })
    else
        print('^1Error: qb-target not found but Config.UseTarget is enabled^7')
    end
end

local function SpawnNPC()
    if npcSpawned then return end
    
    local model = GetHashKey(Config.NPCModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    npcPed = CreatePed(4, model, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1.0, Config.NPCLocation.w, false, true)
    
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    
    TaskStartScenarioInPlace(npcPed, Config.NPCScenario, 0, true)
    
    CreateNPCBlip()
    
    SetupTarget()
    
    npcSpawned = true
end

local function DeleteNPC()
    if npcPed ~= nil then
        DeleteEntity(npcPed)
        npcPed = nil
        npcSpawned = false
    end
    
    RemoveNPCBlip()
end

-- Event Handlers
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SpawnNPC()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DeleteNPC()
    CleanupMission()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SpawnNPC()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    DeleteNPC()
    CleanupMission()
end)

RegisterNetEvent('alpha-mission:client:startMission', function()
    if missionActive then
        QBCore.Functions.Notify("Mission already in progress", "error")
        return
    end
    
    if missionCooldown then
        local minutes = math.floor(cooldownTimer / 60)
        local seconds = cooldownTimer % 60
        QBCore.Functions.Notify("Mission on cooldown. Available in " .. minutes .. "m " .. seconds .. "s", "error")
        return
    end
    
    TriggerServerEvent('alpha-mission:server:giveBagItem')
    
    missionActive = true
    missionStage = 1
    
    CreateDeliveryNPC()
    
    QBCore.Functions.Notify("Mission started. Take the package to the marked location.", "success")
    
    TriggerEvent('alpha-mission:client:updateUI')
end)

RegisterNetEvent('alpha-mission:client:deliverPackage', function()
    if not missionActive or missionStage ~= 1 then
        QBCore.Functions.Notify("You don't have a package to deliver", "error")
        return
    end
        QBCore.Functions.TriggerCallback('alpha-mission:server:hasBagItem', function(hasBag)
        if not hasBag then
            QBCore.Functions.Notify("You don't have the package", "error")
            return
        end
        
        TriggerServerEvent('alpha-mission:server:removeBagItem')
        
        missionStage = 2
        
        exports['alpha-mission']:SetDisplay(false)
        
        if deliveryBlip then
            RemoveBlip(deliveryBlip)
            deliveryBlip = nil
        end
        
        SpawnEnemyVehicles()
        
        QBCore.Functions.Notify("Package delivered. Defend yourself against incoming enemies!", "primary")
        
        TriggerEvent('alpha-mission:client:updateUI')
        
        CreateThread(function()
            while missionActive and missionStage == 2 do
                if CheckAllEnemiesDead() then
                    missionStage = 3
                    
                    deliveryBlip = AddBlipForCoord(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
                    SetBlipSprite(deliveryBlip, 280) 
                    SetBlipDisplay(deliveryBlip, 4)
                    SetBlipScale(deliveryBlip, 0.8)
                    SetBlipColour(deliveryBlip, 2) 
                    SetBlipAsShortRange(deliveryBlip, false)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Return to Big Boss")
                    EndTextCommandSetBlipName(deliveryBlip)
                    SetBlipRoute(deliveryBlip, true)
                    
                    QBCore.Functions.Notify("All enemies defeated. Return to the Big Boss to complete the mission.", "success")
                    
                    TriggerEvent('alpha-mission:client:updateUI')
                    
                    break
                end
                Wait(1000)
            end
        end)
    end)
end)

RegisterNetEvent('alpha-mission:client:completeMission', function()
    if not missionActive or missionStage ~= 3 then
        QBCore.Functions.Notify("You don't have a mission to complete", "error")
        return
    end
    
    missionStage = 4
    
    TriggerServerEvent('alpha-mission:server:giveReward')
    
    QBCore.Functions.Notify("Mission completed. You received your reward.", "success")
    
    TriggerEvent('alpha-mission:client:updateUI')
    
    StartMissionCooldown()
    
    CleanupMission()
end)

RegisterNetEvent('alpha-mission:client:missionFailed', function()
    if not missionActive then return end
    
    QBCore.Functions.Notify("Mission failed. Try again after the cooldown.", "error")
    
    StartMissionCooldown()
    
    CleanupMission()
end)

RegisterNetEvent('alpha-mission:client:updateUI', function()
    SendNUIMessage({
        type = "update",
        missionData = {
            active = missionActive,
            stage = missionStage,
            cooldown = missionCooldown,
            cooldownTime = cooldownTimer,
            friends = teamMembers
        }
    })
end)

RegisterNetEvent('alpha-mission:client:updateTeam', function(team)
    teamMembers = team
    
    SendNUIMessage({
        type = "updateTeam",
        team = team
    })
end)

RegisterNetEvent('alpha-mission:client:interactWithNPC', function()
    if missionActive and missionStage == 3 then
        TriggerEvent('alpha-mission:client:completeMission')
        return
    end
    
    if missionActive then
        QBCore.Functions.Notify("Complete your current mission first.", "error")
        return
    end
    
    if missionCooldown then
        local minutes = math.floor(cooldownTimer / 60)
        local seconds = cooldownTimer % 60
        QBCore.Functions.Notify("Mission on cooldown. Available in " .. minutes .. "m " .. seconds .. "s", "error")
        return
    end
    
    TriggerEvent('alpha-mission:client:openMissionUI', 'bigboss')
end)

CreateThread(function()
    while true do
        Wait(1000)
        
        if missionActive and missionStage > 0 and missionStage < 4 then
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) then
                TriggerEvent('alpha-mission:client:missionFailed')
            end
        end
    end
end)

CreateThread(function()
    if not Config.EnableInteraction or Config.UseTarget then return end
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        
        local npcPos = vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
        local dist = #(pos - npcPos)
        
        if dist < 5.0 then
            sleep = 0
            if dist < Config.InteractionDistance then
                local text = Config.InteractionText
                if missionActive and missionStage == 3 then
                    text = "Press E to complete mission"
                end
                
                DrawText3D(npcPos.x, npcPos.y, npcPos.z + 1.0, text)
                if IsControlJustPressed(0, 38) then
                    TriggerEvent('alpha-mission:client:interactWithNPC')
                end
            end
        end
        
        if deliveryNPC and missionActive and missionStage == 1 then
            local deliveryPos = GetEntityCoords(deliveryNPC)
            local deliveryDist = #(pos - deliveryPos)
            
            if deliveryDist < 5.0 then
                sleep = 0
                if deliveryDist < Config.InteractionDistance then
                    DrawText3D(deliveryPos.x, deliveryPos.y, deliveryPos.z + 1.0, "Press E to deliver package")
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('alpha-mission:client:deliverPackage')
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end
