#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties


if [ ! -d ~/$PROJECT_ID/spinnaker-marketplace-sampleapp ]; then
  bold 'Creating GCR repo "spinnaker-marketplace-sampleapp" in Spinnaker project...'
  gcloud source repos create spinnaker-marketplace-sampleapp
  mkdir -p ~/$PROJECT_ID
  gcloud source repos clone spinnaker-marketplace-sampleapp ~/$PROJECT_ID/spinnaker-marketplace-sampleapp
fi

bold 'Adding/Updating Kubernetes config files, sample Go application, and cloud build files in sample repo...'
cp -r ~/spinnaker-for-gcp/sampleapp/templates/csr/config ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/
cp -r ~/spinnaker-for-gcp/sampleapp/templates/csr/src ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/
cp ~/spinnaker-for-gcp/sampleapp/templates/csr/Dockerfile ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/

cat ~/spinnaker-for-gcp/sampleapp/templates/csr/cloudbuild_yaml.template | envsubst '$BUCKET_NAME' > ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/cloudbuild.yaml
cat ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/config/staging/replicaset_yaml.template | envsubst > ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/config/staging/replicaset.yaml
rm ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/config/staging/replicaset_yaml.template
cat ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/config/prod/replicaset_yaml.template | envsubst > ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/config/prod/replicaset.yaml
rm ~/$PROJECT_ID/spinnaker-marketplace-sampleapp/config/prod/replicaset_yaml.template

cwd=$(pwd)
cd ~/$PROJECT_ID/spinnaker-marketplace-sampleapp
git add *
git commit -m "Bootstrap with source, build, and manifest files."
git push
cd $cwd

bold "Configuring Kubernetes services for prod and staging..."
kubectl apply -f ~/spinnaker-for-gcp/sampleapp/templates/csr/config/staging/service.yaml
kubectl apply -f ~/spinnaker-for-gcp/sampleapp/templates/csr/config/prod/service.yaml

if [ ! -f ~/spinnaker-for-gcp/sampleapp/trigger ]; then
  bold "Creating Cloud Build build trigger for sample app..."
  gcloud alpha builds triggers create cloud-source-repositories \
    --repo spinnaker-marketplace-sampleapp \
    --branch_pattern master \
    --build_config cloudbuild.yaml \
    --included_files "src/*" &> ~/spinnaker-for-gcp/sampleapp/trigger
fi

bold "Creating sampleapp Spinnaker application..."
~/spin app save --application-name sampleapp --cloud-providers kubernetes --owner-email $IAP_USER

bold 'Creating "Deploy to Staging" Spinnaker pipeline...'
cat ~/spinnaker-for-gcp/sampleapp/templates/pipelines/deploystaging_json.template | envsubst  > ~/spinnaker-for-gcp/sampleapp/templates/pipelines/deploystaging.json
~/spin pi save -f ~/spinnaker-for-gcp/sampleapp/templates/pipelines/deploystaging.json

export DEPLOY_STAGING_PIPELINE_ID=$(~/spin pi get -a sampleapp -n 'Deploy to Staging' | jq -r '.id')

bold 'Creating "Deploy to Prod" Spinnaker pipeline...'
cat ~/spinnaker-for-gcp/sampleapp/templates/pipelines/deployprod_json.template | envsubst  > ~/spinnaker-for-gcp/sampleapp/templates/pipelines/deployprod.json
~/spin pi save -f ~/spinnaker-for-gcp/sampleapp/templates/pipelines/deployprod.json
