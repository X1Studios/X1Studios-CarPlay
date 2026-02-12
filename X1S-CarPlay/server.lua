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

    -- 🔥 REPLACE current song instead of queueing
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
