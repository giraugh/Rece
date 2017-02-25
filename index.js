const {app, BrowserWindow} = require('electron')
const path = require('path')
const url = require('url')
const pug = require('electron-pug')({pretty: true})

let win

function createWindow () {
  win = new BrowserWindow({width: 1300, height: 800, frame: false})

  win.loadURL(url.format({
    pathname: path.join(__dirname, 'web', 'index.pug'),
    protocol: 'file:',
    slashes: true
  }))

  win.on('closed', () => {
    win = null
  })

  //Dev Tools
  if (require(path.join(__dirname, 'package.json')).showDevTools) {
    win.webContents.openDevTools()
  }
}

app.on('ready', ()=>{
  createWindow()
})

app.on('window-all-closed', () => {
    app.quit()
})
