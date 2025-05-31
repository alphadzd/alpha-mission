local QBCore = exports['qb-core']:GetCoreObject()
local display = false
local missionData = {
    active = false,
    stage = 0,
    cooldown = false,
    cooldownTime = 0,
    deliveryLocation = nil,
    deliveryBlip = nil,
    deliveryNPC = nil,
    enemyPeds = {},
    enemyVehicles = {},
    friends = {}
}


RegisterNUICallback('close', function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('startMission', function(data, cb)
    TriggerEvent('alpha-mission:client:startMission')
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('inviteFriend', function(data, cb)
    local friendId = tonumber(data.playerId)
    if not friendId then
        QBCore.Functions.Notify("Invalid player ID", "error")
        cb('error')
        return
    end
    
    TriggerServerEvent('alpha-mission:server:invitePlayer', friendId)
    cb('ok')
end)

RegisterNUICallback('acceptInvite', function(data, cb)
    TriggerServerEvent('alpha-mission:server:acceptInvite', data.leaderId)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('declineInvite', function(data, cb)
    TriggerServerEvent('alpha-mission:server:declineInvite', data.leaderId)
    SetDisplay(false)
    cb('ok')
end)


function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
        missionData = missionData
    })
    
    
    if not bool then
        DestroyMissionCamera()
    end
end

function OpenMissionUI(missionType, extraData)
    missionData.type = missionType
    missionData.extraData = extraData or {}
    
    SetDisplay(true)
    
    
    if missionType == "bigboss" then
        CreateCameraAnimation()
    end
end

function OpenInviteUI(leaderId, leaderName)
    SetDisplay(true)
    SendNUIMessage({
        type = "invite",
        leaderId = leaderId,
        leaderName = leaderName
    })
end

local activeCam = nil

function CreateCameraAnimation()
    local playerPed = PlayerPedId()
    local npcCoords = vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
    
    
    activeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(activeCam, true)
    RenderScriptCams(true, true, 500, true, true)
    
    
    local midPoint = vector3(
        (GetEntityCoords(playerPed).x + npcCoords.x) / 2,
        (GetEntityCoords(playerPed).y + npcCoords.y) / 2,
        (GetEntityCoords(playerPed).z + npcCoords.z) / 2 + 0.5
    )
    
    
    local camPos = vector3(
        midPoint.x + 1.8,
        midPoint.y + 0.7,
        midPoint.z + 0.4
    )
    
    SetCamCoord(activeCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(activeCam, midPoint.x, midPoint.y, midPoint.z)
    
    
    ShakeCam(activeCam, "HAND_SHAKE", 0.3)
end

function DestroyMissionCamera()
    if activeCam then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(activeCam, false)
        DestroyCam(activeCam, true)
        activeCam = nil
    end
end


function Lerp(a, b, t)
    return a + (b - a) * t
end


RegisterNetEvent('alpha-mission:client:openMissionUI', function(missionType, extraData)
    OpenMissionUI(missionType, extraData)
end)

RegisterNetEvent('alpha-mission:client:inviteReceived', function(leaderId, leaderName)
    OpenInviteUI(leaderId, leaderName)
    QBCore.Functions.Notify("You received a mission invite from " .. leaderName, "primary")
end)


exports('OpenMissionUI', OpenMissionUI)
exports('SetDisplay', SetDisplay)
