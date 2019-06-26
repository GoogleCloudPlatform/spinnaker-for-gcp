#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties

~/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

pushd ~/spinnaker-for-gcp/tutorials/helloworldwebapp

if [ ! -d ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp ]; then
  bold 'Creating GCR repo "spinnaker-marketplace-helloworldwebapp" in Spinnaker project...'
  gcloud source repos create spinnaker-marketplace-helloworldwebapp
  mkdir -p ~/$PROJECT_ID
  gcloud source repos clone spinnaker-marketplace-helloworldwebapp ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp
fi

bold 'Adding/Updating Kubernetes config files, sample Go application, and cloud build files in sample repo...'
cp -r templates/csr/config ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/
cp -r templates/csr/src ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/
cp templates/csr/Dockerfile ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/

cat templates/csr/cloudbuild_yaml.template | envsubst '$BUCKET_NAME' > ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/cloudbuild.yaml
cat ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/config/staging/replicaset_yaml.template | envsubst > ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/config/staging/replicaset.yaml
rm ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/config/staging/replicaset_yaml.template
cat ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/config/prod/replicaset_yaml.template | envsubst > ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/config/prod/replicaset.yaml
rm ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp/config/prod/replicaset_yaml.template

pushd ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp

git add *
git commit -m "Add source, build, and manifest files."
git push

popd

bold "Configuring Kubernetes services for prod and staging..."
kubectl apply -f templates/csr/config/staging/service.yaml
kubectl apply -f templates/csr/config/prod/service.yaml

if [ -z $(gcloud alpha builds triggers list --filter triggerTemplate.repoName=spinnaker-marketplace-helloworldwebapp --format 'get(id)') ]; then
  bold "Creating Cloud Build build trigger for helloworld app..."
  gcloud alpha builds triggers create cloud-source-repositories \
    --repo spinnaker-marketplace-helloworldwebapp \
    --branch_pattern master \
    --build_config cloudbuild.yaml \
    --included_files "src/**,config/**"
fi

bold "Creating helloworldwebapp Spinnaker application..."
~/spin app save --application-name helloworldwebapp --cloud-providers kubernetes --owner-email $IAP_USER

bold 'Creating "Deploy to Staging" Spinnaker pipeline...'
cat templates/pipelines/deploystaging_json.template | envsubst  > templates/pipelines/deploystaging.json
~/spin pi save -f templates/pipelines/deploystaging.json

export DEPLOY_STAGING_PIPELINE_ID=$(~/spin pi get -a helloworldwebapp -n 'Deploy to Staging' | jq -r '.id')

bold 'Creating "Deploy to Prod" Spinnaker pipeline...'
cat templates/pipelines/deployprod_json.template | envsubst  > templates/pipelines/deployprod.json
~/spin pi save -f templates/pipelines/deployprod.json

popd
