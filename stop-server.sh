#!/usr/bin/env bash

DGRAPH_CONTAINER_NAME=graphd-dgraph

if docker ps -a --format '{{.Names}}' | grep -Eq "^${DGRAPH_CONTAINER_NAME}\$"; then
  echo "Stopping dgraph server..."
  docker stop $DGRAPH_CONTAINER_NAME
else
  echo "Not running!"
fi
echo "Done."
