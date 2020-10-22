#!/usr/bin/env bash

DGRAPH_CONTAINER_NAME=graphd-dgraph

if docker ps -a --format '{{.Names}}' | grep -Eq "^${DGRAPH_CONTAINER_NAME}\$"; then
  echo "Already running..."
else
  echo "Starting local dgraph server via Docker..."
  docker run --name $DGRAPH_CONTAINER_NAME --rm -p 9082:9080 -d dgraph/standalone:master
fi
echo "Done."
