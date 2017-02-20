const {app, BrowserWindow} = require('electron')
const path = require('path')
const url = require('url')

let win

function createWindow () {
  win = new BrowserWindow({width: 1300, height: 800, frame: false})

  win.loadURL(url.format({
    pathname: path.join(__dirname, 'web', 'index.html'),
    protocol: 'file:',
    slashes: true
  }))

  win.on('closed', () => {
    win = null
  })

  win.webContents.openDevTools()
}

app.on('ready', ()=>{
  createWindow()
})

app.on('window-all-closed', () => {
    app.quit()
})
