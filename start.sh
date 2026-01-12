#!/bin/bash

export LANG=zh_TW.UTF-8
export LC_ALL=zh_TW.UTF-8
export LANGUAGE=zh_TW:zh

# 清除舊的 VNC lock 檔案
rm -rf /tmp/.X*-lock /tmp/.X11-unix

# 啟動 VNC Server
# :1 對應 port 5901
vncserver :1 \
    -geometry 1920x1080 \
    -depth 24 \
    -localhost no

echo "VNC Server 已啟動在 port 5901"
echo "預設密碼: password"
echo "連線方式: vnc://your-ip:5901"

# 等待 VNC 啟動完成
sleep 2

# 設定 DISPLAY 並啟動 Chromium with CDP
export DISPLAY=:1
chromium-cdp &

echo ""
echo "Chrome DevTools Protocol 已啟動"
echo "WebSocket: ws://your-ip:9222"
echo "HTTP: http://your-ip:9222/json"

# 保持容器運行
sleep 2 && tail -f /home/user/.vnc/*.log
