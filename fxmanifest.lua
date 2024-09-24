fx_version 'cerulean'
game 'gta5'
author 'Faraway Development'
description 'Survival HUD'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'sounds/index.html'

files {
    'sounds/index.html',
    'sounds/heartbeat.ogg',
    'sounds/hunger.ogg',
    'sounds/thirst.ogg'
}

dependencies {
    'ox_lib',
}