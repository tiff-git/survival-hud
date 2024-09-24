Config = {}

Config.HealthThresholds = {
    Low = 70, -- 50% of 200%
    Critical = 60 -- 37.5% of 200%
}

Config.HungerThresholds = {
    Low = 20
}

Config.ThirstThresholds = {
    Low = 20
}

Config.Stamina = {
    Max = 100,
    RegenRate = 1,
    ExhaustionPenalty = 0.5
}

Config.SoundEffects = {
    Heartbeat = 'heartbeat.ogg',
    Hunger = 'growl.ogg',
    Thirst = 'cough.ogg',
    HeavyBreathing = 'heavy_breathing.ogg'
}

Config.ShowDebugHUD = false -- Toggle this to show/hide the debug HUD