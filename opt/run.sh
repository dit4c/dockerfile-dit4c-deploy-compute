#!/bin/sh

set -e

echo "Setting up for portal at $PORTAL_URL"

PROXY_PORT=${PROXY_PORT:-80}
DIT4C_VERSION=${DIT4C_VERSION:-"latest"}
DOCKER_HOST=${DOCKER_HOST:-"unix:///var/run/docker.sock"}
DOCKER_NETWORK=${DOCKER_NETWORK:-"bridge"}

echo "Getting this container ID..."
THIS_CONTAINER=$(cat /proc/self/mountinfo | grep hostname |
  grep -Eo "containers/[0-9a-f]*" | cut -d / -f 2)

echo "Checking Docker client..."
THIS_CONTAINER=$(docker version > /dev/null &&
  docker inspect $THIS_CONTAINER | jq -r '.[0].Id')

DOCKER_VOLUME_BINDS=$(docker inspect $THIS_CONTAINER |
  jq -r '.[0].HostConfig.Binds | map("-v "+.) | join(" ")')
echo "Starting containers with volume binds: $DOCKER_VOLUME_BINDS"

DOCKER_NETWORK=$(docker inspect $THIS_CONTAINER |
  jq -r '.[0].NetworkSettings.Networks | keys | .[0]')
echo "Starting containers on network: $DOCKER_NETWORK"

dockerIP() {
  docker inspect -f "{{.NetworkSettings.Networks.$DOCKER_NETWORK.IPAddress}}" $1
}

# Start or create gatehouse and machineshop servers
docker start dit4c_gatehouse || \
  docker run -d --name dit4c_gatehouse \
    --net=$DOCKER_NETWORK \
    -e PORTAL_URL=$PORTAL_URL \
    -e DOCKER_HOST=$DOCKER_HOST \
    $DOCKER_VOLUME_BINDS \
    dit4c/dit4c-platform-gatehouse:$DIT4C_VERSION

docker start dit4c_machineshop || \
  docker run -d --name dit4c_machineshop \
    --net=$DOCKER_NETWORK \
    -v /opt/dit4c-machineshop:/etc/dit4c-machineshop \
    -v /var/log/dit4c_machineshop/supervisor:/var/log/supervisor \
    -e PORTAL_URL=$PORTAL_URL \
    -e DOCKER_HOST=$DOCKER_HOST \
    $DOCKER_VOLUME_BINDS \
    dit4c/dit4c-platform-machineshop:$DIT4C_VERSION

docker start dit4c_cnproxy || \
  docker run -d --name dit4c_cnproxy \
    -p ${PROXY_PORT}:8080 \
    --net=$DOCKER_NETWORK \
    --add-host=gatehouse:$(dockerIP dit4c_gatehouse) \
    --add-host=gatehouse:$(dockerIP dit4c_machineshop) \
    -e PORTAL_URL=$PORTAL_URL \
    dit4c/dit4c-platform-cnproxy
