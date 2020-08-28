#!/bin/bash
set -x

for chart in ./*; do
    if [ -f "$chart/Chart.yaml" ]; then
        helm package $chart -d dist
    fi
done

helm repo index --url https://duyet.github.io/charts/dist ./dist
cp ./dist/index.yaml ./index.yaml