#!/usr/bin/env bash

WORKING_DIR=$(dirname "$0")
CONTAINER_NAME="surrealdb-demo-e2e"
DATA_PATH="${PWD}/data/$CONTAINER_NAME"

echo " "
echo "Configuring SurrealDB container"
echo "-----------------------------------------"
echo "WORKING_DIR=$WORKING_DIR"
echo "CONTAINER_NAME=$CONTAINER_NAME"
echo "DATA_PATH=$DATA_PATH"
echo "-----------------------------------------"
echo " "


if [ -d "$DATA_PATH" ]; then
  echo "Previous test dump found - removing '$DATA_PATH'..."
  rm -rf "$DATA_PATH"
fi


echo "Checking if docker deamon is running"

if ! docker info > /dev/null 2>&1; then
  echo "Please start the docker daemon"
  exit 1
fi

echo "Checking for current docker container"

if docker ps --filter "name=$CONTAINER_NAME" | grep $CONTAINER_NAME; then
    echo "Container already running, stopping container..."
    docker stop $CONTAINER_NAME
fi

if docker container ls -a --filter "name=$CONTAINER_NAME" | grep $CONTAINER_NAME; then
    echo "Container already exists, removing container..."
    docker rm $CONTAINER_NAME
fi

echo "Starting container..."
docker run -d -v $DATA_PATH:/data --name $CONTAINER_NAME -p 8000:8000 surrealdb/surrealdb:1.0.0 start --user root --pass root  -- "memory"

echo " "
echo "Container is running!"
echo "Waiting 5 seconds"
echo "-----------------------------------------"


set +e
echo "Waiting for surreal to be ready..."
tries=0
while [[ $tries < 5 ]]; do
        nc -z -v -w5 0.0.0.0 8000 2>/dev/null && echo "Ready!" && exit 0 || sleep 1
        tries=$((tries + 1))
done

echo "ERROR: Surreal is unhealthy!"
exit 1
