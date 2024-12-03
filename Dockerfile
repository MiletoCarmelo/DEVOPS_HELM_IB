# Première étape : Builder pour toutes les architectures
FROM --platform=$BUILDPLATFORM ubuntu:22.04 as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "Building on $BUILDPLATFORM, targeting $TARGETPLATFORM"

# Installation des dépendances communes
RUN apt-get update && apt-get install -y \
    wget \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Installation de noVNC pour toutes les architectures
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# Téléchargement d'IB Gateway
WORKDIR /tmp
RUN wget -q https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-linux-x64.sh && \
    chmod +x ibgateway-stable-standalone-linux-x64.sh

# Stage pour ARM64 (Raspberry Pi)
FROM ubuntu:22.04 as arm64

# Installation des dépendances ARM
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
    gcc-multilib \
    g++-multilib \
    && rm -rf /var/lib/apt/lists/*

# Installation de Box64/86 pour ARM
COPY scripts/install-box.sh /install-box.sh
RUN chmod +x /install-box.sh && /install-box.sh

# Stage pour AMD64 (x86_64)
FROM ubuntu:22.04 as amd64

# Installation des dépendances x86_64
RUN apt-get update && apt-get install -y \
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

# Stage final conditionnel
FROM ${TARGETPLATFORM/linux\//} as final

# Copie des fichiers depuis le builder
COPY --from=builder /opt/novnc /opt/novnc
COPY --from=builder /tmp/ibgateway-stable-standalone-linux-x64.sh /tmp/

# Installation d'IB Gateway selon l'architecture
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        BOX64_LOG=1 box64 /tmp/ibgateway-stable-standalone-linux-x64.sh -q -dir /opt/ibgateway; \
    else \
        /tmp/ibgateway-stable-standalone-linux-x64.sh -q -dir /opt/ibgateway; \
    fi && \
    rm /tmp/ibgateway-stable-standalone-linux-x64.sh

# Configuration commune
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start-script.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4001 4002 5900 6080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]