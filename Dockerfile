FROM arm64v8/ubuntu:22.04

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

# Création des répertoires nécessaires
WORKDIR /root
RUN mkdir -p /root/Jts /opt/IBController

# Installation de IBController
RUN cd /opt/IBController && \
    wget https://github.com/IbcAlpha/IBC/releases/download/3.15.1/IBController-3.15.1.zip && \
    unzip IBController-3.15.1.zip && \
    rm IBController-3.15.1.zip

# Configuration des variables d'environnement
ENV DISPLAY=:1
ENV TWS_MAJOR_VRSN=10.19
ENV TWS_PATH=/root/Jts
ENV IBC_PATH=/opt/IBController
ENV IBC_INI=/opt/IBController/config.ini
ENV TWS_CONFIG_PATH=/root/Jts

# Configuration IBController
RUN echo "IbLoginId=%" >> /opt/IBController/config.ini && \
    echo "IbPassword=%" >> /opt/IBController/config.ini && \
    echo "ForceTwsApiPort=4001" >> /opt/IBController/config.ini && \
    echo "ReadOnlyLogin=no" >> /opt/IBController/config.ini && \
    echo "AcceptIncomingConnectionAction=accept" >> /opt/IBController/config.ini

# Copie du script de démarrage
COPY scripts/start-script.sh ./start.sh
RUN chmod +x start.sh

EXPOSE 4001 4002 5900

ENTRYPOINT ["./start.sh"]