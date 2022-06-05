fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"

shared_script {
     'config.lua',
     'shared/shared_main.lua'
}

client_scripts {
     '@PolyZone/client.lua',
     'client/client.lua',
     'client/menu/menu.lua',
     'client/menu/functions.lua',
}

server_script {
     '@oxmysql/lib/MySQL.lua',
     'server/server.lua',
     'server/server_lib/lib.lua' }

-- dependency 'oxmysql'
ui_page 'html/door.html'

files {
     'html/*.html',
     'html/*.js',
     'html/*.css',
     'html/sounds/*.ogg',
}

lua54 'yes'
