docker ps  # list all running containers : 910c4e32e663

docker stop $(docker ps -q)

docker rm $(docker ps -a -q)

docker build -t ibgateway-vnc:latest .

# Pour l'API IB
# Pour les données de marché
# Pour VNC
# Pour noVNC (interface web)

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

# docker run -d \
#   -p 4001:4001 \
#   -p 4002:4002 \
#   -p 5901:5901 \
#   -p 6080:6080 \
#   -e VNC_SERVER_PASSWORD='test123' \
#   -e TWS_USERID='testuser' \
#   -e TWS_PASSWORD='testpass' \
#   -e IB_ACCOUNT='testaccount' \
#   ibgateway-vnc:latest


# bash opt/ibgateway/ibgateway

# docker ps 
# docker exec -it 965c2deaea60 /bin/bash