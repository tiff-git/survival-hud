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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/heartbeat.ogg',
    'html/hunger.ogg',
    'html/thirst.ogg'
}

dependencies {
    'ox_lib',
}