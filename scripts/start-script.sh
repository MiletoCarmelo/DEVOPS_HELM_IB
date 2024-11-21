#!/bin/bash

# Démarrage de Xvfb
Xvfb :1 -screen 0 1024x768x24 &

# Attente que Xvfb soit prêt
sleep 2

# Démarrage de VNC
x11vnc -display :1 -nopw -forever &

# Démarrage d'IB Gateway
./IBController.sh
