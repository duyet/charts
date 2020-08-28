#!/bin/bash
set -x

DIST_DIR=".dist"

for chart in ./*; do
    if [ -f "$chart/Chart.yaml" ]; then
        helm package $chart -d $DIST_DIR
    fi
done

helm repo index --url https://duyet.github.io/charts/dist $DIST_DIR
cp $DIST_DIR/index.yaml ./index.yaml