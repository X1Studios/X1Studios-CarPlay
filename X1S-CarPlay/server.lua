AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print([[
 __   __  __   ____  
 \ \ / / /_ | / ___| 
  \ V /   | | \___ \ 
  / _ \   | |  ___) |
 /_/ \_\  |_| |____/ 

  X1Studios CarPlay
    ]])
end)

local queues = {}

RegisterNetEvent('x1s:playSong', function(data)
    local net = data.net
    local link = data.link

    queues[net] = { link }

    TriggerClientEvent('x1s:syncSong', -1, {
        link = link,
        net = net
    })
end)

RegisterNetEvent('x1s:skip', function(net)
    if queues[net] then
        queues[net] = nil
    end
end)

RegisterNetEvent('x1s:setVolume', function(vol, net)
    TriggerClientEvent('x1s:updateVolume', -1, vol, net)
end)

CreateThread(function()
    while true do
        Wait(250)

        for net, link in pairs(queues) do
            if link then
                local veh = NetworkGetEntityFromNetworkId(net)
                if veh and DoesEntityExist(veh) then
                    local coords = GetEntityCoords(veh)
                    TriggerClientEvent("x1s:updateCarPos", -1, net, coords)
                end
            end
        end
    end
end)

local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)

local versionUrl = "https://github.com/X1Studios/X1Studios-CarPlay/blob/main/version.txt"

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
            print("^5Download:^0 https://github.com/YourName/YourRepo")
            print("^3-------------------------------------------------------^0")
        end
    end, "GET")
end

CreateThread(function()
    Wait(3000)
    CheckForUpdates()
end)
