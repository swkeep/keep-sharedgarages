fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"

shared_script {
     'config.lua',
     'shared/shared_main.lua'
}

client_scripts {
     '@PolyZone/client.lua',
     'client/lib.lua',
     'client/client.lua',
     'client/menu/menu.lua',
     'client/menu/functions.lua',
}

server_script {
     '@oxmysql/lib/MySQL.lua',
     'server/lib.lua',
     'server/server.lua',
}

dependency 'oxmysql'

lua54 'yes'
