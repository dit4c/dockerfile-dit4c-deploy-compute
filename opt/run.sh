#!/bin/bash

echo "Setting up for portal at $PORTAL_URL"

DOCKER_SOCKET="/var/run/docker.sock"

if [ ! -S $DOCKER_SOCKET ]
then
    echo "Host Docker socket should be mounted at $DOCKER_SOCKET"
    exit 1
fi

# Start or create gatehouse and machineshop servers
docker start dit4c_gatehouse || \
  docker run -d --name dit4c_gatehouse \
    -p 80:80 \
    -v /var/log/dit4c_gatehouse/supervisor:/var/log/supervisor \
    -v /var/log/dit4c_gatehouse/nginx:/var/log/nginx \
    -e PORTAL_URL=$PORTAL_URL \
    -v $DOCKER_SOCKET:$DOCKER_SOCKET \
    dit4c/dit4c-platform-gatehouse
    
docker start dit4c_machineshop || \
  docker run -d --name dit4c_machineshop \
    -p 8080:8080 \
    -v /var/log/dit4c_machineshop/supervisor:/var/log/supervisor \
    -e PORTAL_URL=$PORTAL_URL \
    -v $DOCKER_SOCKET:$DOCKER_SOCKET \
    dit4c/dit4c-platform-machineshop
