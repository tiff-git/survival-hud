local QBCore = exports['qb-core']:GetCoreObject()
local healthNotified = false
local criticalHealthNotified = false
local playerPed = PlayerPedId()
local stamina = Config.Stamina.Max
local isExhausted = false
local lastHungerNotification = 100
local lastThirstNotification = 100
local hudVisible = false

Citizen.CreateThread(function()
    while true do
        Wait(0)
        DisplayRadar(false) -- Hide the radar (map) in the bottom left corner
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(500) -- Reduce the frequency of checks to every half second
        
        playerPed = PlayerPedId()
        
        -- Check if playerPed is valid
        if playerPed and playerPed ~= -1 then
            local health = GetEntityHealth(playerPed)
            local maxHealth = 200 -- Set the maximum health to 200 for display purposes
            local hunger = GetPlayerHunger()
            local thirst = GetPlayerThirst()
            
            -- Check if health is valid
            if health and health > 0 then
                -- Normalize health to a percentage with 200 as the maximum
                local normalizedHealth = (health / maxHealth) * 100
                
                -- Handle Effects
                HandleHealthEffects(normalizedHealth, health)
                HandleHungerEffects(hunger)
                HandleThirstEffects(thirst)
                HandleStaminaMechanics()
                
                -- Update HUD
                UpdateHUD(normalizedHealth, hunger, thirst)
            end
        end
    end
end)

function HandleHealthEffects(normalizedHealth, health)
    if normalizedHealth < Config.HealthThresholds.Low then
        NotifyHealthLow()
    else
        StopScreenEffect("Rampage")
        healthNotified = false
    end
    
    if normalizedHealth < Config.HealthThresholds.Critical then
        NotifyHealthCritical(normalizedHealth, health)
    else
        criticalHealthNotified = false
    end
end

function NotifyHealthLow()
    if not healthNotified then
        lib.notify({
            title = 'Health Warning',
            description = 'Health is low! Seek safety and find medical attention.',
            type = 'error',
            duration = 3000,
            position = 'top-right'
        })
        -- Add red screen edges and blood spatters
        StartScreenEffect("Rampage", 0, true)
        healthNotified = true
    end
end

function NotifyHealthCritical(normalizedHealth, health)
    if not criticalHealthNotified then
        -- Add heartbeat sound
        Citizen.CreateThread(function()
            while normalizedHealth < Config.HealthThresholds.Critical and health > 0 do
                SendNUIMessage({
                    action = 'playSound',
                    sound = 'heartbeat'
                })
                Wait(1000) -- Play the sound every second
                health = GetEntityHealth(playerPed)
                normalizedHealth = (health / 200) * 100
            end
        end)
        criticalHealthNotified = true
    end
end

function HandleHungerEffects(hunger)
    if hunger < Config.HungerThresholds.Low then
        NotifyHungerLow(hunger)
    end
end

function NotifyHungerLow(hunger)
    if hunger <= lastHungerNotification - 5 or lastHungerNotification == 100 then
        lib.notify({
            title = 'Hunger Warning',
            description = 'You are hungry!',
            type = 'warning',
            duration = 3000,
            position = 'top-right'
        })
        -- Play hunger sound
        SendNUIMessage({
            action = 'playSound',
            sound = 'hunger'
        })
        -- Apply slowdowns and decreased strength
        lastHungerNotification = hunger
    end
end

function HandleThirstEffects(thirst)
    if thirst < Config.ThirstThresholds.Low then
        NotifyThirstLow(thirst)
    else
        ClearTimecycleModifier()
    end
end

function NotifyThirstLow(thirst)
    if thirst <= lastThirstNotification - 5 or lastThirstNotification == 100 then
        lib.notify({
            title = 'Thirst Warning',
            description = 'You are thirsty!',
            type = 'warning',
            duration = 3000,
            position = 'top-right'
        })
        -- Play thirst sound
        SendNUIMessage({
            action = 'playSound',
            sound = 'thirst'
        })
        -- Apply blurry vision and slow health drain
        SetTimecycleModifier("BarryFadeOut")
        lastThirstNotification = thirst
    end
end

function HandleStaminaMechanics()
    local playerPed = PlayerPedId()

    if IsPedRunning(playerPed) then
        stamina = stamina - 1
        if stamina < 0 then
            stamina = 0
            -- Apply stumbling effect
        end
    else
        stamina = stamina + Config.Stamina.RegenRate
        if stamina > Config.Stamina.Max then
            stamina = Config.Stamina.Max
        end
    end
    
    if stamina < 20 then
        ApplyExhaustionEffects()
    else
        ResetExhaustionEffects()
    end
    
    if stamina == 0 then
        isExhausted = true
    end
end

function ApplyExhaustionEffects()
    -- Play heavy breathing sound
    SendNUIMessage({
        action = 'playSound',
        sound = 'heavyBreathing'
    })
    -- Change running animation to injured style
    if not isExhausted then
        RequestAnimSet("move_m@injured")
        while not HasAnimSetLoaded("move_m@injured") do
            Citizen.Wait(0)
        end
        SetPedMovementClipset(playerPed, "move_m@injured", 1.0)
        isExhausted = true
    end
end

function ResetExhaustionEffects()
    -- Reset to normal running animation if stamina is sufficient
    if isExhausted then
        ResetPedMovementClipset(playerPed, 1.0)
        isExhausted = false
    end
end

function UpdateHUD(normalizedHealth, hunger, thirst)
    local hudText = string.format("Health: %d%%\nStamina: %d%%\nHunger: %d%%\nThirst: %d%%", 
        math.floor(normalizedHealth), math.floor(stamina), math.floor(hunger), math.floor(thirst))

    local hudOptions = {
        position = 'top-center',
        style = {
            borderRadius = '10px',
            backgroundColor = '#333',
            color = '#fff',
            padding = '10px',
            fontSize = '14px',
            textAlign = 'center',
            opacity = 0.6
        }
    }

    if not hudVisible then
        lib.showTextUI(hudText, hudOptions)
        hudVisible = true
    else
        -- Update the HUD text
        local isOpen, currentText = lib.isTextUIOpen()
        if isOpen and currentText ~= hudText then
            lib.showTextUI(hudText, hudOptions)
        end
    end
end

function GetPlayerStamina()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.metadata then
        return playerData.metadata["stamina"] or 100
    end
    return 100
end

function GetPlayerHunger()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.metadata then
        return playerData.metadata["hunger"] or 100
    end
    return 100
end

function GetPlayerThirst()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.metadata then
        return playerData.metadata["thirst"] or 100
    end
    return 100
end