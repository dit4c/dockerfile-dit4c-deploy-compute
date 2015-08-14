#!/bin/sh

echo "Setting up for portal at $PORTAL_URL"

PROXY_PORT=${PROXY_PORT:-80}
DIT4C_VERSION=${DIT4C_VERSION:-"latest"}
DOCKER_SOCKET="/var/run/docker.sock"

if [ ! -S $DOCKER_SOCKET ]
then
    echo "Host Docker socket should be mounted at $DOCKER_SOCKET"
    exit 1
fi

# Start or create gatehouse and machineshop servers
docker start dit4c_gatehouse || \
  docker run -d --name dit4c_gatehouse \
    -e PORTAL_URL=$PORTAL_URL \
    -v $DOCKER_SOCKET:$DOCKER_SOCKET \
    dit4c/dit4c-platform-gatehouse:$DIT4C_VERSION

docker start dit4c_machineshop || \
  docker run -d --name dit4c_machineshop \
    -v /opt/dit4c-machineshop:/etc/dit4c-machineshop \
    -v /var/log/dit4c_machineshop/supervisor:/var/log/supervisor \
    -e PORTAL_URL=$PORTAL_URL \
    -v $DOCKER_SOCKET:$DOCKER_SOCKET \
    dit4c/dit4c-platform-machineshop:$DIT4C_VERSION

docker start dit4c_cnproxy || \
  docker run -d --name dit4c_cnproxy \
    -p ${PROXY_PORT}:8080 \
    --link dit4c_gatehouse:gatehouse \
    --link dit4c_machineshop:machineshop \
    -e PORTAL_URL=$PORTAL_URL \
    dit4c/dit4c-platform-cnproxy
