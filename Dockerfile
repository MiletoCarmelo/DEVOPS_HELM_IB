# Première étage : Builder commun
FROM --platform=$BUILDPLATFORM ubuntu:22.04 as builder

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

ARG TARGETARCH

# Installation des dépendances de base communes
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    python3 \
    xvfb \
    x11vnc \
    supervisor \
    default-jre \
    libxtst6 \
    libxrender1 \
    libxi6 \
    socat \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

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

# Configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start-script.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4001 4002 5900 6080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]