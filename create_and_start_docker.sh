docker ps  # list all running containers : 910c4e32e663
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

# Supprimer l'image spécifique
docker rmi ib-gateway-arm64

# Restart container id 
docker restart 03cab036d93a

# docker ps
# docker images

##########################################################################

# macbook / linux
docker build -t ibgateway-vnc:latest .
# AARCH64
docker build --platform linux/arm64 -t ib-gateway-arm64 -f Dockerfile.aarch64 .
docker build --no-cache --platform linux/arm64 -t ib-gateway-arm64 -f Dockerfile.aarch64 .

docker build --memory=1g --cpu-quota=50000 --platform linux/arm64 -t ib-gateway-arm64 -f Dockerfile.aarch64 .

# 50% d'utilisation d'un CPU (--cpu-quota=50000)


# Pour l'API IB
# Pour les données de marché
# Pour VNC
# Pour noVNC (interface web)

# macbook / linux
docker run -d \
  -p 4001:4001 \
  -p 4002:4002 \
  -p 5901:5901 \
  -p 6080:6080 \
  -e VNC_SERVER_PASSWORD='test123' \
  -e TWS_USERID='testuser' \
  -e TWS_PASSWORD='testpass' \
  -e IB_ACCOUNT='testaccount' \
  ibgateway-vnc:latest

# AARCH64
docker run -d \
  -p 4001:4001 \
  -p 4002:4002 \
  -p 5900:5900 \
  -p 6080:6080 \
  ib-gateway-arm64:latest


##
# bash opt/ibgateway/ibgateway

# docker ps 
# docker exec -it 965c2deaea60 /bin/bash

# depuis le macbook sur la raspberry :
# http://100.64.102.47:6080/vnc.html

# en localhost dans la raspberry ou macbook :
# http://localhost:6080/vnc.html
