local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local missionTeams = {} -- Format: { leaderId = { members = {playerId = {id, name}}, active = bool } }

print('^2Alpha House Robbery^7: ^5Mission Script Initialized^7')

-- Helper Functions
local function GetPlayerName(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return "Unknown" end
    
    return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
end

local function IsPlayerInTeam(playerId)
    -- Check if player is a team leader
    if missionTeams[playerId] then return true, playerId end
    
    -- Check if player is a team member
    for leaderId, team in pairs(missionTeams) do
        for memberId, _ in pairs(team.members) do
            if tonumber(memberId) == tonumber(playerId) then
                return true, leaderId
            end
        end
    end
    
    return false, nil
end

local function RemovePlayerFromTeam(playerId)
    local isInTeam, leaderId = IsPlayerInTeam(playerId)
    
    if not isInTeam then return false end
    
    if tonumber(leaderId) == tonumber(playerId) then
        -- Player is the leader, disband the team
        missionTeams[leaderId] = nil
    else
        -- Player is a member, remove from team
        if missionTeams[leaderId] and missionTeams[leaderId].members[playerId] then
            missionTeams[leaderId].members[playerId] = nil
        end
    end
    
    return true
end

local function GetTeamMembers(leaderId)
    if not missionTeams[leaderId] then return {} end
    
    local members = {}
    for memberId, memberData in pairs(missionTeams[leaderId].members) do
        table.insert(members, {id = memberId, name = memberData.name})
    end
    
    return members
end

-- Item Management
QBCore.Functions.CreateUseableItem(Config.BagItem, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('QBCore:Notify', source, "This is a mission item and cannot be used directly.", "error")
end)

-- Mission Events
RegisterNetEvent('alpha-mission:server:giveBagItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Add bag item to inventory
    Player.Functions.AddItem(Config.BagItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.BagItem], "add")
    
    -- Notify team members
    local isInTeam, leaderId = IsPlayerInTeam(src)
    if isInTeam and missionTeams[leaderId] then
        for memberId, _ in pairs(missionTeams[leaderId].members) do
            TriggerClientEvent('QBCore:Notify', memberId, "Your team leader has started the mission.", "primary")
        end
    end
end)

RegisterNetEvent('alpha-mission:server:removeBagItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Remove bag item from inventory
    Player.Functions.RemoveItem(Config.BagItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.BagItem], "remove")
end)

RegisterNetEvent('alpha-mission:server:giveReward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local rewardNotifications = {}
    
    -- Give cash reward if enabled
    if Config.Rewards.Cash.Enabled then
        local reward = math.random(Config.Rewards.Cash.MinAmount, Config.Rewards.Cash.MaxAmount)
        Player.Functions.AddMoney('cash', reward)
        table.insert(rewardNotifications, "$" .. reward .. " cash")
    end
    
    -- Give item rewards if enabled
    if Config.Rewards.Items.Enabled then
        for _, item in pairs(Config.Rewards.Items.PossibleItems) do
            if math.random(1, 100) <= item.chance then
                Player.Functions.AddItem(item.name, item.amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], "add")
                table.insert(rewardNotifications, item.amount .. "x " .. (QBCore.Shared.Items[item.name].label or item.name))
            end
        end
    end
    
    -- Check for special rewards
    if Config.Rewards.SpecialRewards.Enabled then
        if math.random(1, 100) <= Config.Rewards.SpecialRewards.ChanceToTrigger then
            -- Determine which special reward to give
            local totalChance = 0
            for _, reward in pairs(Config.Rewards.SpecialRewards.PossibleRewards) do
                totalChance = totalChance + reward.chance
            end
            
            local roll = math.random(1, totalChance)
            local currentChance = 0
            
            for _, reward in pairs(Config.Rewards.SpecialRewards.PossibleRewards) do
                currentChance = currentChance + reward.chance
                if roll <= currentChance then
                    -- Handle different reward types
                    if reward.type == "vehicle" then
                        -- Logic to give vehicle would go here
                        -- This would typically involve a server callback to a vehicle system
                        TriggerClientEvent('QBCore:Notify', src, "You won a " .. reward.model .. "! Check your garage.", "success")
                        table.insert(rewardNotifications, "a " .. reward.model .. " vehicle")
                    elseif reward.type == "weapon" then
                        Player.Functions.AddItem(string.lower(reward.name), 1)
                        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[string.lower(reward.name)], "add")
                        table.insert(rewardNotifications, "a " .. reward.name)
                    end
                    break
                end
            end
        end
    end
    
    -- Send notification about all rewards
    if #rewardNotifications > 0 then
        TriggerClientEvent('QBCore:Notify', src, "Mission completed! You received: " .. table.concat(rewardNotifications, ", "), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Mission completed!", "success")
    end
    
    -- Give rewards to team members
    local isInTeam, leaderId = IsPlayerInTeam(src)
    if isInTeam and missionTeams[leaderId] then
        for memberId, _ in pairs(missionTeams[leaderId].members) do
            if tonumber(memberId) ~= tonumber(src) then -- Don't give reward to leader twice
                local TeamMember = QBCore.Functions.GetPlayer(tonumber(memberId))
                if TeamMember then
                    local memberRewardNotifications = {}
                    
                    -- Cash rewards for team members
                    if Config.Rewards.Cash.Enabled then
                        local memberReward = math.random(Config.Rewards.Cash.TeamMemberMinAmount, Config.Rewards.Cash.TeamMemberMaxAmount)
                        TeamMember.Functions.AddMoney('cash', memberReward)
                        table.insert(memberRewardNotifications, "$" .. memberReward .. " cash")
                    end
                    
                    -- Item rewards for team members (at reduced chance)
                    if Config.Rewards.Items.Enabled then
                        for _, item in pairs(Config.Rewards.Items.PossibleItems) do
                            if math.random(1, 100) <= (item.chance / 2) then -- Half the chance for team members
                                TeamMember.Functions.AddItem(item.name, math.ceil(item.amount / 2)) -- Half the amount
                                TriggerClientEvent('inventory:client:ItemBox', tonumber(memberId), QBCore.Shared.Items[item.name], "add")
                                table.insert(memberRewardNotifications, math.ceil(item.amount / 2) .. "x " .. (QBCore.Shared.Items[item.name].label or item.name))
                            end
                        end
                    end
                    
                    -- Send notification about all rewards to team member
                    if #memberRewardNotifications > 0 then
                        TriggerClientEvent('QBCore:Notify', tonumber(memberId), "Mission completed! You received: " .. table.concat(memberRewardNotifications, ", "), "success")
                    else
                        TriggerClientEvent('QBCore:Notify', tonumber(memberId), "Mission completed!", "success")
                    end
                end
            end
        end
    end
end)

-- Team Management
RegisterNetEvent('alpha-mission:server:invitePlayer', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then 
        TriggerClientEvent('QBCore:Notify', src, "Player not found.", "error")
        return 
    end
    
    -- Check if target is already in a team
    local targetInTeam, _ = IsPlayerInTeam(targetId)
    if targetInTeam then
        TriggerClientEvent('QBCore:Notify', src, "This player is already in a team.", "error")
        return
    end
    
    -- Check if player is in a team but not the leader
    local playerInTeam, leaderId = IsPlayerInTeam(src)
    if playerInTeam and tonumber(leaderId) ~= tonumber(src) then
        TriggerClientEvent('QBCore:Notify', src, "Only the team leader can invite players.", "error")
        return
    end
    
    -- Create team if not exists
    if not missionTeams[src] then
        missionTeams[src] = {
            members = {},
            active = false
        }
    end
    
    -- Send invite to target
    local leaderName = GetPlayerName(src)
    TriggerClientEvent('alpha-mission:client:inviteReceived', targetId, src, leaderName)
    TriggerClientEvent('QBCore:Notify', src, "Invite sent to " .. GetPlayerName(targetId), "success")
end)

RegisterNetEvent('alpha-mission:server:acceptInvite', function(leaderId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is already in a team
    local playerInTeam, _ = IsPlayerInTeam(src)
    if playerInTeam then
        TriggerClientEvent('QBCore:Notify', src, "You are already in a team.", "error")
        return
    end
    
    -- Check if team exists
    if not missionTeams[leaderId] then
        TriggerClientEvent('QBCore:Notify', src, "The team no longer exists.", "error")
        return
    end
    
    -- Add player to team
    missionTeams[leaderId].members[src] = {
        id = src,
        name = GetPlayerName(src)
    }
    
    -- Notify leader and member
    TriggerClientEvent('QBCore:Notify', leaderId, GetPlayerName(src) .. " has joined your team.", "success")
    TriggerClientEvent('QBCore:Notify', src, "You have joined " .. GetPlayerName(leaderId) .. "'s team.", "success")
    
    -- Update team members for all team members
    local teamMembers = GetTeamMembers(leaderId)
    TriggerClientEvent('alpha-mission:client:updateTeam', leaderId, teamMembers)
    
    for memberId, _ in pairs(missionTeams[leaderId].members) do
        TriggerClientEvent('alpha-mission:client:updateTeam', memberId, teamMembers)
    end
end)

RegisterNetEvent('alpha-mission:server:declineInvite', function(leaderId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Notify leader
    TriggerClientEvent('QBCore:Notify', leaderId, GetPlayerName(src) .. " has declined your invitation.", "error")
end)

RegisterNetEvent('alpha-mission:server:notifyTeam', function(message)
    local src = source
    local isInTeam, leaderId = IsPlayerInTeam(src)
    
    if not isInTeam then return end
    
    -- Notify team members
    if missionTeams[leaderId] then
        for memberId, _ in pairs(missionTeams[leaderId].members) do
            TriggerClientEvent('QBCore:Notify', memberId, message, "primary")
        end
    end
end)

-- Callbacks
QBCore.Functions.CreateCallback('alpha-mission:server:hasBagItem', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then 
        cb(false)
        return 
    end
    
    local hasItem = Player.Functions.GetItemByName(Config.BagItem)
    cb(hasItem ~= nil)
end)

-- Player Disconnection
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Remove player from team
    RemovePlayerFromTeam(src)
end)
