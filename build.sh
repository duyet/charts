#!/bin/bash
set -x

DIST_DIR=dist

for chart in ./*; do
    if [ -f "$chart/Chart.yaml" ]; then
        helm dependency update $chart
        helm dependency build $chart
        helm package $chart -d $DIST_DIR
    fi
done

helm repo index --url https://duyet.github.io/charts/$DIST_DIR $DIST_DIR
cp $DIST_DIR/index.yaml ./index.yaml