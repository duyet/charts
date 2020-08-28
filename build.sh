#!/bin/bash
set -x

DIST_DIR=dist

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add bitnami https://charts.bitnami.com/bitnami

for chart in ./*; do
    if [ -f "$chart/Chart.yaml" ]; then
        mkdir $chart/charts
        helm dependency update $chart
        helm dependency build $chart
        helm package $chart -d $DIST_DIR
    fi
done

helm repo index --url https://duyet.github.io/charts/$DIST_DIR $DIST_DIR
cp $DIST_DIR/index.yaml ./index.yaml