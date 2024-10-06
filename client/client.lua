---@diagnostic disable: unused-local
local QBCore = exports['qb-core']:GetCoreObject()
local healthNotified = false
local criticalHealthNotified = false
local playerPed = PlayerPedId()
local stamina = Config.Stamina.Max
local isExhausted = false
local lastHungerNotification = 100
local lastThirstNotification = 100

Citizen.CreateThread(function()
    while true do
        Wait(0)
        DisplayRadar(false) -- This will hide the radar (map) in the bottom left corner
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
                
                -- Health Effects
                HandleHealthEffects(normalizedHealth, health)
                
                -- Hunger Effects
                HandleHungerEffects(hunger)
                
                -- Thirst Effects
                HandleThirstEffects(thirst)
                
                -- Stamina Mechanics
                HandleStaminaMechanics()
            else
                print("Invalid health value")
            end
        else
            print("Invalid playerPed value")
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0) -- Draw the HUD every frame
        
        -- Draw HUD if enabled
        if Config.ShowDebugHUD then
            local health = GetEntityHealth(playerPed)
            local maxHealth = 200 -- Set the maximum health to 200 for display purposes
            local normalizedHealth = (health / maxHealth) * 100
            local hunger = GetPlayerHunger()
            local thirst = GetPlayerThirst()
            
            DrawTextOnScreen("Health: " .. math.floor(normalizedHealth) .. "%", 0.05, 0.05)
            DrawTextOnScreen("Stamina: " .. stamina .. "%", 0.05, 0.08)
            DrawTextOnScreen("Hunger: " .. hunger .. "%", 0.05, 0.11)
            DrawTextOnScreen("Thirst: " .. thirst .. "%", 0.05, 0.14)
        end
    end
end)

function HandleHealthEffects(normalizedHealth, health)
    if normalizedHealth < Config.HealthThresholds.Low then
        if not healthNotified then
            lib.notify({
                title = 'Health Warning',
                description = 'Health is low!',
                type = 'error',
                duration = 3000,
                position = 'top-right'
            })
            -- Add red screen edges and blood spatters
            StartScreenEffect("Rampage", 0, true)
            healthNotified = true
        end
    else
        StopScreenEffect("Rampage")
        healthNotified = false
    end
    
    if normalizedHealth < Config.HealthThresholds.Critical then
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
    else
        criticalHealthNotified = false
    end
end

function HandleHungerEffects(hunger)
    if hunger < Config.HungerThresholds.Low then
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
end

function HandleThirstEffects(thirst)
    if thirst < Config.ThirstThresholds.Low then
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
    else
        ClearTimecycleModifier()
    end
end

function HandleStaminaMechanics()
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
        -- Play heavy breathing sound
        SendNUIMessage({
            action = 'playSound',
            sound = 'heavyBreathing'
        })
        -- Change running animation
        if not isExhausted then
            RequestAnimSet("move_m@drunk@verydrunk")
            while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                Citizen.Wait(0)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", 1.0)
            isExhausted = true
        end
    else
        if isExhausted then
            ResetPedMovementClipset(playerPed, 1.0)
            isExhausted = false
        end
    end
    
    if stamina == 0 then
        -- Apply exhaustion effects
        isExhausted = true
    else
        isExhausted = false
    end
end

function DrawTextOnScreen(text, x, y)
    SetTextFont(7) -- Changed font to Pricedown
    SetTextProportional(1)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(1, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
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