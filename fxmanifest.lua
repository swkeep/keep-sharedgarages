fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"
version '2.0.4'

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
     'dev-tool/client.lua' --no-commit
}

server_script {
     '@oxmysql/lib/MySQL.lua',
     'server/lib.lua',
     'server/server.lua',
     'dev-tool/server.lua' --no-commit
}

dependency 'oxmysql'

lua54 'yes'
