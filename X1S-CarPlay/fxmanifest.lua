fx_version 'cerulean'
game 'gta5'

author 'X1Studios'
description 'CarPlay'
version '1.1.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/skip-red.png',
    'html/img/skip-black.png'
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_script 'server.lua'
