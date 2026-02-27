AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print([[
 __   __  __   ____  
 \ \ / / /_ | / ___| 
  \ V /   | | \___ \ 
  / _ \   | |  ___) |
 /_/ \_\  |_| |____/ 

  X1Studios CarPlay
       v1.1.0
    ]])
end)

-------------------------------------------------
-- Vehicle Queues
-------------------------------------------------
local vehicleQueues = {}
-- [net] = { queue = {}, current = songObject }

local function GetVehicleState(net)
    if not vehicleQueues[net] then
        vehicleQueues[net] = {
            queue = {},
            current = nil
        }
    end
    return vehicleQueues[net]
end

local function BroadcastQueue(net)
    local data = vehicleQueues[net]
    if not data then
        TriggerClientEvent("x1s:updateQueue", -1, net, {})
        return
    end

    TriggerClientEvent("x1s:updateQueue", -1, net, data.queue)
end

-------------------------------------------------
-- Play Next Song
-------------------------------------------------
local function PlayNext(net)
    local data = vehicleQueues[net]
    if not data then return end

    TriggerClientEvent("x1s:destroyCarSound", -1, net)

    data.current = nil

    if #data.queue == 0 then
        BroadcastQueue(net)
        vehicleQueues[net] = nil
        return
    end

    local nextSong = table.remove(data.queue, 1)
    data.current = nextSong

    TriggerClientEvent('x1s:syncSong', -1, {
        link = nextSong.link,
        net = net,
        title = nextSong.title,
        artist = nextSong.artist,
        thumbnail = nextSong.thumbnail
    })

    BroadcastQueue(net)
end

-------------------------------------------------
-- Play Song / Add Queue
-------------------------------------------------
RegisterNetEvent('x1s:playSong', function(data)
    if not data or not data.net or data.net <= 0 then return end

    local net = data.net
    local state = GetVehicleState(net)

    local songData = {
        link = data.link,
        title = data.title or "Unknown Title",
        artist = data.artist or "Unknown Artist",
        thumbnail = data.thumbnail or ""
    }

    if not state.current then
        state.current = songData

        TriggerClientEvent('x1s:syncSong', -1, {
            link = songData.link,
            net = net,
            title = songData.title,
            artist = songData.artist,
            thumbnail = songData.thumbnail
        })

        BroadcastQueue(net)
        return
    end

    table.insert(state.queue, songData)
    BroadcastQueue(net)
end)

-------------------------------------------------
-- Manual Skip
-------------------------------------------------
RegisterNetEvent('x1s:skip', function(net)
    if not net then return end
    if not vehicleQueues[net] then return end

    PlayNext(net)
end)

-------------------------------------------------
-- Auto Finish / Skip
-------------------------------------------------
local finishCooldown = {}

RegisterNetEvent('x1s:songFinished', function(net)
    if not net then return end
    if not vehicleQueues[net] then return end

    if finishCooldown[net] then return end
    finishCooldown[net] = true

    PlayNext(net)

    SetTimeout(1500, function()
        finishCooldown[net] = nil
    end)
end)

-------------------------------------------------
-- Remove From Queue
-------------------------------------------------

RegisterNetEvent("x1s:removeFromQueue", function(net, index)

    local state = vehicleQueues[net]
    if not state then return end
    if not state.queue then return end

    local removeIndex = tonumber(index)
    if not removeIndex then return end

    table.remove(state.queue, removeIndex + 1)

    BroadcastQueue(net)
end)

-------------------------------------------------
-- Volume Sync
-------------------------------------------------
RegisterNetEvent('x1s:setVolume', function(vol, net)
    if not net then return end
    TriggerClientEvent('x1s:updateVolume', -1, vol, net)
end)

-------------------------------------------------
-- Vehicle Delete Detection
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(2000)

        for net, _ in pairs(vehicleQueues) do
            local veh = NetworkGetEntityFromNetworkId(net)

            if veh == 0 or not DoesEntityExist(veh) then
                TriggerClientEvent("x1s:destroyCarSound", -1, net)
                vehicleQueues[net] = nil
            end
        end
    end
end)

-------------------------------------------------
-- Update Checker
-------------------------------------------------
local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)

local versionUrl = "https://raw.githubusercontent.com/X1Studios/X1Studios-CarPlay/main/version.txt"

local function CheckForUpdates()
    PerformHttpRequest(versionUrl, function(statusCode, responseText, headers)
        if statusCode ~= 200 then
            print("^1[Update Checker] Unable to check for updates (HTTP Error " .. statusCode .. ")^0")
            return
        end

        local latestVersion = responseText:gsub("%s+", "")

        if latestVersion == currentVersion then
            print("^2[Update Checker] " .. resourceName .. " is up to date! (v" .. currentVersion .. ")^0")
        else
            print("^3-------------------------------------------------------^0")
            print("^1[Update Checker] Update Available for " .. resourceName .. "!^0")
            print("^3Current Version:^0 " .. currentVersion)
            print("^2Latest Version:^0 " .. latestVersion)
            print("^5Download:^0 https://github.com/X1Studios/X1Studios-CarPlay")
            print("^3-------------------------------------------------------^0")
        end
    end, "GET")
end

CreateThread(function()
    Wait(3000)
    CheckForUpdates()
end)
