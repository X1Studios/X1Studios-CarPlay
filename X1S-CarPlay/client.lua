local vehicleNet = nil
local soundId = nil
local finishSent = false
local skipLock = false

local activeSounds = {}

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function getCurrentVehicleNet()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    return NetworkGetNetworkIdFromEntity(veh)
end

local function isVehicleOwner(veh)
    return NetworkGetEntityOwner(veh) == PlayerId()
end

-------------------------------------------------
-- Open CarPlay
-------------------------------------------------
RegisterCommand("carplay", function()
    local net = getCurrentVehicleNet()
    if not net then return end

    vehicleNet = net
    soundId = "car_" .. net

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "show" })
end)

-------------------------------------------------
-- Close UI
-------------------------------------------------
RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hide" })
    cb("ok")
end)

-------------------------------------------------
-- Play Song
-------------------------------------------------
RegisterNUICallback("play", function(data, cb)
    local net = getCurrentVehicleNet()
    if not net then cb("fail"); return end

    vehicleNet = net
    soundId = "car_" .. net
    finishSent = false

    TriggerServerEvent("x1s:playSong", {
        link = data.link,
        title = data.title,
        artist = data.artist,
        thumbnail = data.thumbnail,
        net = net
    })

    cb("ok")
end)

-------------------------------------------------
-- Pause / Resume
-------------------------------------------------
RegisterNUICallback("pause", function(_, cb)
    if soundId and exports.xsound:soundExists(soundId) then
        exports.xsound:Pause(soundId)
    end
    cb("ok")
end)

RegisterNUICallback("resume", function(_, cb)
    if soundId and exports.xsound:soundExists(soundId) then
        exports.xsound:Resume(soundId)
        finishSent = false
    end
    cb("ok")
end)

-------------------------------------------------
-- Skip
-------------------------------------------------
RegisterNUICallback("skip", function(_, cb)
    local net = getCurrentVehicleNet()
    if net then
        finishSent = true
        skipLock = true

        TriggerServerEvent("x1s:skip", net)

        SetTimeout(1500, function()
            skipLock = false
        end)
    end
    cb("ok")
end)

-------------------------------------------------
-- Remove Song From Queue
-------------------------------------------------
RegisterNUICallback("remove", function(data, cb)
    local net = getCurrentVehicleNet()
    if not net then cb("ok") return end

    TriggerServerEvent("x1s:removeFromQueue", net, data.index)
    cb("ok")
end)

-------------------------------------------------
-- Volume
-------------------------------------------------
RegisterNUICallback("volume", function(data, cb)
    local net = getCurrentVehicleNet()
    if not net then cb("ok"); return end

    local id = "car_" .. net

    if exports.xsound:soundExists(id) then
        exports.xsound:setVolume(id, data.vol)
    end

    TriggerServerEvent("x1s:setVolume", data.vol, net)

    cb("ok")
end)

-------------------------------------------------
-- Volume Sync
-------------------------------------------------
RegisterNetEvent("x1s:updateVolume", function(vol, net)
    local id = "car_" .. net
    if exports.xsound:soundExists(id) then
        exports.xsound:setVolume(id, vol)
    end
end)

-------------------------------------------------
-- Sync Song
-------------------------------------------------
RegisterNetEvent("x1s:syncSong", function(data)

    local veh = NetToVeh(data.net)
    if veh == 0 then return end

    local id = "car_" .. data.net

    finishSent = false
    skipLock = false

    if exports.xsound:soundExists(id) then
        exports.xsound:Destroy(id)
        Wait(100)
    end

    exports.xsound:PlayUrlPos(
        id,
        data.link,
        Config.DefaultVolume,
        GetEntityCoords(veh),
        false
    )

    exports.xsound:Distance(id, Config.SoundDistance)

    activeSounds[data.net] = id

    local pedVeh = GetVehiclePedIsIn(PlayerPedId(), false)

    if pedVeh == veh then
        vehicleNet = data.net
        soundId = id

        SendNUIMessage({
            action = "nowPlaying",
            song = {
                title = data.title,
                artist = data.artist,
                thumbnail = data.thumbnail
            }
        })
    end
end)

-------------------------------------------------
-- Queue Update
-------------------------------------------------
RegisterNetEvent("x1s:updateQueue", function(net, queue)

    local currentNet = getCurrentVehicleNet()

    if currentNet == net then
        vehicleNet = net

        SendNUIMessage({
            action = "updateQueue",
            queue = queue
        })
    end
end)

-------------------------------------------------
-- Auto Skip + Global Position
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(300)

        -- Update all sounds for everyone
        for net, id in pairs(activeSounds) do

            local veh = NetToVeh(net)

            if veh ~= 0 and DoesEntityExist(veh) then
                if exports.xsound:soundExists(id) then
                    exports.xsound:Position(id, GetEntityCoords(veh))
                end
            else
                activeSounds[net] = nil
            end
        end

        if vehicleNet and soundId then

            local veh = NetToVeh(vehicleNet)

            if veh == 0 or not DoesEntityExist(veh) then

                if exports.xsound:soundExists(soundId) then
                    exports.xsound:Destroy(soundId)
                end

                vehicleNet = nil
                soundId = nil
                finishSent = false
                skipLock = false

                SendNUIMessage({ action = "stop" })
                goto continue
            end

            if exports.xsound:soundExists(soundId) then

                local cur = exports.xsound:getTimeStamp(soundId) or 0
                local dur = exports.xsound:getMaxDuration(soundId) or 0
                local isPlaying = exports.xsound:isPlaying(soundId)

                if isPlaying then
                    finishSent = false
                end

                -------------------------------------------------
                -- STABLE AUTHORITY CHECK
                -------------------------------------------------
                if isVehicleOwner(veh) and not finishSent and not skipLock then
                    if dur > 0 and isPlaying and cur >= (dur - 0.25) then
                        finishSent = true
                        TriggerServerEvent("x1s:songFinished", vehicleNet)
                    end
                end

                if dur > 0 then
                    SendNUIMessage({
                        action = "progress",
                        current = cur,
                        duration = dur
                    })
                end
            end
        end

        ::continue::
    end
end)

-------------------------------------------------
-- Destroy Sound
-------------------------------------------------
RegisterNetEvent("x1s:destroyCarSound", function(net)

    local id = "car_" .. net

    if exports.xsound:soundExists(id) then
        exports.xsound:Destroy(id)
    end

    activeSounds[net] = nil

    if vehicleNet == net then
        finishSent = false
        skipLock = false
        SendNUIMessage({ action = "stop" })
    end
end)

-------------------------------------------------
-- Exit Vehicle Cleanup
-------------------------------------------------
CreateThread(function()

    local wasInVehicle = false

    while true do
        Wait(500)

        local ped = PlayerPedId()
        local inVeh = IsPedInAnyVehicle(ped, false)

        if wasInVehicle and not inVeh then

            SetNuiFocus(false, false)
            SendNUIMessage({ action = "hide" })

            vehicleNet = nil
            soundId = nil
            finishSent = false
            skipLock = false
        end

        wasInVehicle = inVeh
    end
end)
