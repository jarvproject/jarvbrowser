const { app, BrowserWindow, ipcMain, globalShortcut } = require('electron');
const path = require('path');
const Database = require('better-sqlite3');

// Настройка путей базы данных (хранится в конфигах пользователя локально)
const dbPath = path.join(app.getPath('userData'), 'jarv_vault.db');
const db = new Database(dbPath);

// Инициализация таблицы паролей (Пункт 4)
db.prepare(`
  CREATE TABLE IF NOT EXISTS credentials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    site TEXT,
    login TEXT,
    password TEXT
  )
`).run();

// Перехватчики IPC для связи страницы и Node.js базы данных
ipcMain.handle('save-password', (event, { site, login, password }) => {
  const insert = db.prepare('INSERT INTO credentials (site, login, password) VALUES (?, ?, ?)');
  return insert.run(site, login, password).changes > 0;
});

ipcMain.handle('get-passwords', () => {
  return db.prepare('SELECT * FROM credentials').all();
});

// Агрессивные флаги оптимизации и фикс Vulkan/Wayland (Пункт 5)
app.commandLine.appendSwitch('disable-gpu-vsync');
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('ignore-gpu-blocklist');
app.commandLine.appendSwitch('disable-background-timer-throttling');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1300,
    height: 850,
    backgroundColor: '#121212',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'main.js'), // Переиспользуем файл для моста безопасности, или используйте напрямую ниже:
      experimentalFeatures: true
    }
  });

  // ХАК ДЛЯ ОБХОДА ERR_BLOCKED_BY_RESPONSE (Снимает защиту X-Frame-Options)
  mainWindow.webContents.session.webRequest.onHeadersReceived((details, callback) => {
    const headers = details.responseHeaders;
    // Удаляем блокирующие заголовки сайтов (Пункт 5)
    delete headers['x-frame-options'];
    delete headers['content-security-policy'];
    callback({ cancel: false, responseHeaders: headers });
  });

  mainWindow.loadFile(path.join(__dirname, 'browser', 'i.html'));

  // 1. Открытие консоли разработчика по нажатию F12 (Пункт 1)
  globalShortcut.register('F12', () => {
    if (mainWindow) mainWindow.webContents.toggleDevTools();
  });
  // F5 для быстрой перезагрузки страницы браузера
  globalShortcut.register('F5', () => {
    if (mainWindow) mainWindow.webContents.reload();
  });

  mainWindow.on('closed', () => { mainWindow = null; });
}

// Контекстный мост для безопасной передачи SQL функций в браузерный JS
if (process.type === 'renderer' || !app) {
  const { contextBridge, ipcRenderer } = require('electron');
  contextBridge.exposeInMainWorld('jarvVault', {
    save: (data) => ipcRenderer.invoke('save-password', data),
    getAll: () => ipcRenderer.invoke('get-passwords')
  });
} else {
  app.whenReady().then(createWindow);
  app.on('will-quit', () => { globalShortcut.unregisterAll(); });
  app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
}
