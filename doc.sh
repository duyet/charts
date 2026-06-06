brew install norwoodj/tap/helm-docs

# Loop over all charts folder (contain the Chart.yaml file)
for chart in $(find charts -name Chart.yaml); do
  cd $(dirname $chart)
  # Run helm-docs to generate the README.md file
  helm-docs
  cd -
done
