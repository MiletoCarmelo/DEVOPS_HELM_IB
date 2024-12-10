# Première étage : Builder commun
FROM --platform=$BUILDPLATFORM ubuntu:22.04 AS builder

# Installation des dépendances communes
RUN apt-get update && apt-get install -y \
    wget \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Installation de noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# Téléchargement d'IB Gateway
WORKDIR /tmp
RUN wget -q https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-linux-x64.sh && \
    chmod +x ibgateway-stable-standalone-linux-x64.sh

# Stage final
FROM ubuntu:22.04

# Arguments de construction
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# Variables d'environnement
ENV DISPLAY=:1
ENV VNC_SERVER_PASSWORD=""
ENV TWS_USERID=""
ENV TWS_PASSWORD=""
ENV IB_ACCOUNT=""

# 2 warnings found (use docker --debug to expand):
#     - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VNC_SERVER_PASSWORD") (line 29)
#     - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "TWS_PASSWORD") (line 31)

# Installation des dépendances de base communes
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    python3-numpy \
    xvfb \
    x11vnc \
    x11-utils \
    supervisor \
    default-jre \
    libxtst6 \
    libxrender1 \
    libxi6 \
    socat \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Installation d'ibapi
RUN pip3 install --no-cache-dir ibapi

# Installation des dépendances spécifiques à ARM64
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        apt-get update && \
        apt-get install -y \
            libatomic1 \
            libxft2 \
            && rm -rf /var/lib/apt/lists/* && \
        cd /opt && \
        git clone https://github.com/ptitSeb/box64 && \
        cd box64 && mkdir build && cd build && \
        cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
        make -j4 && make install && \
        cd ../.. && rm -rf box64 && \
        echo "/usr/local/lib64" > /etc/ld.so.conf.d/box64.conf && \
        ldconfig; \
    fi

# Copie des fichiers depuis le builder
COPY --from=builder /opt/novnc /opt/novnc
COPY --from=builder /tmp/ibgateway-stable-standalone-linux-x64.sh /tmp/

# Installation d'IB Gateway selon l'architecture
RUN if [ "$TARGETARCH" = "arm64" ]; then \
    BOX64_LOG=1 box64 /tmp/ibgateway-stable-standalone-linux-x64.sh -q -dir /opt/ibgateway; \
    else \
    /tmp/ibgateway-stable-standalone-linux-x64.sh -q -dir /opt/ibgateway; \
    fi && \
    rm /tmp/ibgateway-stable-standalone-linux-x64.sh


# Configuration d'IB Gateway pour accepter les connexions externes
RUN mkdir -p /root/IBController/Logs && \
    echo "OverrideProp.IbAutoClosedown=no" > /root/IBController/IBController.ini && \
    echo "AllowedConnections=*" >> /root/IBController/IBController.ini && \
    echo "ListenAddress=0.0.0.0" >> /root/IBController/IBController.ini

# Et ajoutons un paramètre pour Java
ENV _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"

# Création du répertoire pour les logs
RUN mkdir -p /var/log && \
    mkdir -p /root/.vnc

# Configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start-script.sh /start.sh
COPY tests/test_co.py /test_co.py

RUN chmod +x /start.sh

# Expose les ports nécessaires
EXPOSE 4001 4002 5900 6080

# Commande de démarrage
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]