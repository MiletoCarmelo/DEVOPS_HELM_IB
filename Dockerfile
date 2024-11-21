# Utiliser une image de base multi-architecture
FROM --platform=$TARGETPLATFORM ubuntu:22.04

# Arguments pour la construction multi-plateforme
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    libxrender1 \
    libxtst6 \
    libxi6 \
    socat \
    x11vnc \
    openjdk-11-jre \
    && rm -rf /var/lib/apt/lists/*

# Création du répertoire de travail
WORKDIR /opt/IBController

# Installation conditionnelle selon l'architecture
RUN case "${TARGETARCH}" in \
        "amd64")  IBGW_DIST="linux-x64" ;; \
        "arm64")  IBGW_DIST="linux-aarch64" ;; \
        *)        IBGW_DIST="linux-x64" ;; \
    esac && \
    wget "https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-${IBGW_DIST}.sh" && \
    chmod +x ibgateway-stable-standalone-${IBGW_DIST}.sh && \
    ./ibgateway-stable-standalone-${IBGW_DIST}.sh -q && \
    rm ibgateway-stable-standalone-${IBGW_DIST}.sh

# Configuration environnement
ENV DISPLAY=:1
ENV TWS_PATH=/root/Jts
ENV IBC_PATH=/opt/IBController
ENV TWS_CONFIG_PATH=/root/Jts

# Copie du script de démarrage
COPY scripts/start-script.sh ./start.sh
RUN chmod +x start.sh

EXPOSE 4001 4002 5900

CMD ["./start.sh"]