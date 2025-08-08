fx_version 'cerulean'
game 'gta5'

author 'beans'
description 'Drug Plane Delivery Script'
version '1.0.0'

shared_script '@ox_lib/init.lua'      -- ✅ This is REQUIRED for using `lib` table
shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'ox_inventory'
}

lua54 'yes'
