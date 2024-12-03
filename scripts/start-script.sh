#!/bin/bash

export DISPLAY=:1

# Configuration du mot de passe VNC
if [ ! -z "$VNC_SERVER_PASSWORD" ]; then
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$VNC_SERVER_PASSWORD" /root/.vnc/passwd
fi

# Attente que Xvfb soit prêt
until xdpyinfo -display :1 >/dev/null 2>&1; do
    echo "Waiting for Xvfb..."
    sleep 1
done

# Démarrage d'IB Gateway selon l'architecture
if [ "$(uname -m)" = "aarch64" ]; then
    export BOX64_LOG=1
    export BOX64_LD_LIBRARY_PATH="/opt/ibgateway/jre/lib/amd64"
    box64 /opt/ibgateway/ibgateway $TWS_USERID $TWS_PASSWORD $IB_ACCOUNT
else
    /opt/ibgateway/ibgateway $TWS_USERID $TWS_PASSWORD $IB_ACCOUNT
fi

# Boucle de surveillance
while true; do
    if ! pgrep -f "ibgateway" > /dev/null; then
        echo "IB Gateway process died, restarting..."
        if [ "$(uname -m)" = "aarch64" ]; then
            box64 /opt/ibgateway/ibgateway $TWS_USERID $TWS_PASSWORD $IB_ACCOUNT
        else
            /opt/ibgateway/ibgateway $TWS_USERID $TWS_PASSWORD $IB_ACCOUNT
        fi
    fi
    sleep 10
done