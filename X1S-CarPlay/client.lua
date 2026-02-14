local vehicleNet = nil
local soundId = nil

-------------------------------------------------
-- SAFE NET TO VEH
-------------------------------------------------
local function GetVehicleFromNet(net)
    if not net or net <= 0 then return 0 end
    if not NetworkDoesNetworkIdExist(net) then return 0 end

    local veh = NetToVeh(net)

    if veh == 0 or not DoesEntityExist(veh) then
        return 0
    end

    return veh
end

-------------------------------------------------
-- Open CarPlay
-------------------------------------------------
RegisterCommand("carplay", function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

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
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then cb("fail") return end

    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then cb("fail") return end

    vehicleNet = NetworkGetNetworkIdFromEntity(veh)
    soundId = "car_" .. vehicleNet

    if exports.xsound:soundExists(soundId) then
        exports.xsound:Destroy(soundId)
        Wait(100)
    end

    TriggerServerEvent("x1s:playSong", {
        link = data.link,
        net = vehicleNet
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
    end
    cb("ok")
end)

-------------------------------------------------
-- Volume
-------------------------------------------------
RegisterNUICallback("volume", function(data, cb)
    if vehicleNet then
        TriggerServerEvent("x1s:setVolume", data.vol, vehicleNet)
    end
    cb("ok")
end)

-------------------------------------------------
-- Sync Song From Server
-------------------------------------------------
RegisterNetEvent("x1s:syncSong", function(data)

    local timeout = 0
    local veh = GetVehicleFromNet(data.net)

    -- wait for entity to exist (fixes warning)
    while veh == 0 and timeout < 50 do
        Wait(100)
        veh = GetVehicleFromNet(data.net)
        timeout = timeout + 1
    end

    if veh == 0 then return end

    vehicleNet = data.net
    soundId = "car_" .. vehicleNet

    if exports.xsound:soundExists(soundId) then
        exports.xsound:Destroy(soundId)
        Wait(100)
    end

    exports.xsound:PlayUrlPos(
        soundId,
        data.link,
        Config.DefaultVolume,
        GetEntityCoords(veh),
        false
    )

    exports.xsound:Distance(soundId, Config.SoundDistance)
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
-- Vehicle Sync + Progress
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(300)

        if soundId and exports.xsound:soundExists(soundId) then

            local veh = GetVehicleFromNet(vehicleNet)

            if veh ~= 0 then
                exports.xsound:Position(soundId, GetEntityCoords(veh))
            end

            local cur = exports.xsound:getTimeStamp(soundId)
            local dur = exports.xsound:getMaxDuration(soundId)

            if cur and dur and dur > 0 then
                SendNUIMessage({
                    action = "progress",
                    current = cur,
                    duration = dur
                })
            end
        end
    end
end)

-------------------------------------------------
-- Close UI On Exit Vehicle
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
        end

        wasInVehicle = inVeh
    end
end)
