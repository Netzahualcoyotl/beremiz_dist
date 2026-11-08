#!/bin/bash

set -e

CONTAINER=beremiz_public_builder_current

docker start "$CONTAINER"
echo "Ejecutando compilación dentro del contenedor: $*"

if docker exec "$CONTAINER" bash -c "build $*"; then
    BUILD_STATUS=0
else
    BUILD_STATUS=$?
fi

docker stop "$CONTAINER" || true

exit "$BUILD_STATUS"
