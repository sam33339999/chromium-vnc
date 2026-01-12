FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_TW.UTF-8
ENV LANGUAGE=zh_TW:zh
ENV LC_ALL=zh_TW.UTF-8

# 安裝基本套件
RUN apt-get update && apt-get install -y \
    # VNC 相關
    tigervnc-standalone-server \
    tigervnc-common \
    # 桌面環境 (輕量級)
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    # Chromium (Debian 有原生套件，不需要 snap)
    chromium \
    # 中文語系支援
    locales \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    ibus \
    ibus-chewing \
    # 其他工具
    sudo \
    wget \
    curl \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 設定繁體中文語系
RUN sed -i '/zh_TW.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen zh_TW.UTF-8 && \
    update-locale LANG=zh_TW.UTF-8

# 建立使用者
RUN useradd -m -s /bin/bash user && \
    echo "user:password" | chpasswd && \
    adduser user sudo

# 設定 VNC
RUN mkdir -p /home/user/.vnc && \
    echo "password" | vncpasswd -f > /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

# 建立 VNC 啟動腳本
RUN echo '#!/bin/bash\n\
export LANG=zh_TW.UTF-8\n\
export LC_ALL=zh_TW.UTF-8\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec startxfce4' > /home/user/.vnc/xstartup && \
    chmod +x /home/user/.vnc/xstartup && \
    chown user:user /home/user/.vnc/xstartup

# 建立啟動腳本
RUN echo '#!/bin/bash\n\
export LANG=zh_TW.UTF-8\n\
export LC_ALL=zh_TW.UTF-8\n\
export LANGUAGE=zh_TW:zh\n\
\n\
# 清除舊的 VNC lock 檔案\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix\n\
\n\
# 啟動 VNC Server\n\
vncserver :1 -geometry 1920x1080 -depth 24 -localhost no\n\
\n\
# 獲取 VNC 進程 PID\n\
VNC_PID=$(pgrep -f "Xtigervnc :1" | head -1)\n\
\n\
echo "VNC Server 已啟動在 port 5901 (PID: $VNC_PID)"\n\
echo "預設密碼: password"\n\
\n\
# 等待 VNC 啟動完成\n\
sleep 2\n\
\n\
# 設定 DISPLAY 並啟動 Chromium with CDP\n\
export DISPLAY=:1\n\
chromium-cdp &\n\
CHROMIUM_PID=$!\n\
\n\
# 等待 Chrome 啟動\n\
sleep 3\n\
\n\
# 使用 socat 轉發 CDP 連線到 0.0.0.0\n\
socat TCP-LISTEN:9223,fork,reuseaddr TCP:127.0.0.1:9222 &\n\
SOCAT_PID=$!\n\
\n\
echo ""\n\
echo "Chrome DevTools Protocol 已啟動 (PID: $CHROMIUM_PID)"\n\
echo "WebSocket (internal): ws://127.0.0.1:9222"\n\
echo "WebSocket (external): ws://your-ip:9223"\n\
echo "HTTP: http://your-ip:9223/json"\n\
echo ""\n\
echo "監控進程: VNC($VNC_PID), Chromium($CHROMIUM_PID), socat($SOCAT_PID)"\n\
echo "當 Chromium 或 VNC 關閉時，容器將自動停止"\n\
\n\
# 監控關鍵進程，任一退出則關閉容器\n\
while true; do\n\
    # 檢查 Chromium 是否還在運行\n\
    if ! kill -0 $CHROMIUM_PID 2>/dev/null; then\n\
        echo "Chromium 已關閉，停止容器..."\n\
        break\n\
    fi\n\
    \n\
    # 檢查 VNC 是否還在運行\n\
    if ! pgrep -f "Xtigervnc :1" >/dev/null 2>&1; then\n\
        echo "VNC Server 已關閉，停止容器..."\n\
        break\n\
    fi\n\
    \n\
    sleep 2\n\
done\n\
\n\
# 清理：關閉所有進程\n\
kill $CHROMIUM_PID $SOCAT_PID 2>/dev/null\n\
vncserver -kill :1 2>/dev/null\n\
echo "容器已停止"' > /start.sh && \
    chmod +x /start.sh

# 設定 Chromium 語系
RUN mkdir -p /home/user/.config/chromium && \
    echo '{"intl":{"accept_languages":"zh-TW,zh,en-US,en"}}' > /home/user/.config/chromium/Local\ State && \
    chown -R user:user /home/user/.config

# 建立 Chromium 啟動腳本（含 CDP）
RUN echo '#!/bin/bash\n\
chromium \
    --remote-debugging-port=9222 \
    --remote-debugging-address=0.0.0.0 \
    --remote-allow-origins=* \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-networking \
    --disable-client-side-phishing-detection \
    --disable-default-apps \
    --disable-extensions \
    --disable-hang-monitor \
    --disable-popup-blocking \
    --disable-prompt-on-repost \
    --disable-sync \
    --disable-translate \
    --metrics-recording-only \
    --safebrowsing-disable-auto-update \
    --lang=zh-TW \
    "$@"' > /usr/local/bin/chromium-cdp && \
    chmod +x /usr/local/bin/chromium-cdp

USER user
WORKDIR /home/user

# VNC port + CDP WebSocket port (9222 internal, 9223 external via socat)
EXPOSE 5901 9222 9223

CMD ["/start.sh"]