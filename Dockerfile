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
# Variables système nécessaires
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1

# 2 warnings found (use docker --debug to expand):
#     - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VNC_SERVER_PASSWORD") (line 29)
#     - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "TWS_PASSWORD") (line 31)

# Installation des dépendances de base communes
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Dépendances pour le développement
    git \
    build-essential \
    cmake \
    # Python et bibliothèques
    python3 \
    python3-pip \
    python3-numpy \
    # Dépendances pour X11 et affichage
    xvfb \
    x11vnc \
    x11-utils \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    # Java Runtime Environment
    default-jre \
    # Bibliothèques graphiques
    libxtst6 \
    libxrender1 \
    libxi6 \
    # Outils divers
    supervisor \
    socat \
    net-tools \
    gzip \
    && rm -rf /var/lib/apt/lists/*


# Installation d'ibapi
RUN pip3 install --no-cache-dir ibapi

# Copie des fichiers depuis le builder
COPY --from=builder /opt/novnc /opt/novnc
COPY --from=builder /tmp/ibgateway-stable-standalone-linux-x64.sh /tmp/

# Installation d'IB Gateway selon l'architecture
RUN bash /tmp/ibgateway-stable-standalone-linux-x64.sh -q -dir /opt/ibgateway; \
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