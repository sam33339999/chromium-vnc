# Chromium + VNC Docker 環境（繁體中文支援 + CDP）

## 功能特點

- ✅ Chromium 瀏覽器
- ✅ Chrome DevTools Protocol (CDP) WebSocket
- ✅ VNC 遠端桌面（TigerVNC）
- ✅ XFCE4 輕量級桌面環境
- ✅ 繁體中文語系支援
- ✅ 中文字體（Noto CJK、文泉驛）
- ✅ 中文輸入法（ibus-chewing 酷音輸入法）


## 使用 Chrome 驗證連線到遠端瀏覽器方法.

> `chrome://inspect` 添加遠端分頁

![01](./assets/chrome-01.png)

![02](./assets/chrome-02.png)

![03](./assets/chrome-03.png)


## 快速開始

### 使用 Docker Compose（推薦）

```bash
# 建置並啟動
docker compose up -d --build

# 查看 log
docker compose logs -f

# 停止
docker compose down
```

### 使用 Docker 指令

```bash
# 建置 image
docker build -t chromium-vnc .

# 啟動容器
docker run -d \
  --name chromium-vnc \
  -p 5901:5901 \
  --shm-size=2g \
  --security-opt seccomp=unconfined \
  chromium-vnc
```

## 連線方式

### Chrome DevTools Protocol (CDP)

容器啟動後，Chromium 會自動開啟並監聽 CDP：

- **WebSocket**: `ws://localhost:9222`
- **HTTP API**: `http://localhost:9222/json`

#### 常用 CDP Endpoints

```bash
# 取得所有可用的 targets（分頁）
curl http://localhost:9222/json

# 取得版本資訊
curl http://localhost:9222/json/version

# 開啟新分頁
curl http://localhost:9222/json/new?http://example.com

# 關閉分頁
curl http://localhost:9222/json/close/{targetId}
```

#### Playwright / Puppeteer 連線範例

```javascript
// Playwright
const browser = await chromium.connectOverCDP('http://localhost:9222');

// Puppeteer
const browser = await puppeteer.connect({
  browserURL: 'http://localhost:9222'
});
```

### VNC 連線資訊

- **位址**: `your-ip:5901`
- **密碼**: `password`

### VNC 客戶端推薦

- **macOS**: 內建「螢幕共享」或 [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
- **Windows**: [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) 或 [TigerVNC](https://tigervnc.org/)
- **Linux**: Remmina、TigerVNC Viewer

### macOS 快速連線

```bash
open vnc://localhost:5901
```

## 自訂設定

### 修改 VNC 密碼

編輯 Dockerfile 中的：
```dockerfile
echo "your-new-password" | vncpasswd -f > /home/user/.vnc/passwd
```

### 修改解析度

編輯 `start.sh` 中的：
```bash
vncserver :1 -geometry 1920x1080 -depth 24
```

常用解析度：
- `1920x1080` (Full HD)
- `2560x1440` (2K)
- `1280x720` (HD)

### 掛載本機目錄

取消 `docker-compose.yml` 中的註解：
```yaml
volumes:
  - ./downloads:/home/user/Downloads
```

## 使用中文輸入法

1. 連線 VNC 後，開啟終端機
2. 執行 `ibus-setup` 設定輸入法
3. 在 Input Method 中加入 Chewing（酷音）
4. 使用 `Ctrl+Space` 切換輸入法

## 疑難排解

### Chromium 無法啟動

確保使用了 `--shm-size=2g` 參數，Chromium 需要較大的共享記憶體。

### 中文顯示亂碼

確認語系環境變數已正確設定：
```bash
docker exec chromium-vnc locale
```

### VNC 連線失敗

檢查容器 log：
```bash
docker logs chromium-vnc
```

## 檔案結構

```
chromium-vnc/
├── Dockerfile          # Docker 映像檔定義
├── docker-compose.yml  # Docker Compose 設定
├── start.sh           # VNC 啟動腳本
└── README.md          # 說明文件
```
