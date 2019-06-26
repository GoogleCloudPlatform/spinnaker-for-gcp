#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties

~/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

pushd ~/spinnaker-for-gcp/samples/helloworldwebapp

if [ ! -d ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp ]; then
  bold 'Creating GCR repo "spinnaker-for-gcp-helloworldwebapp" in Spinnaker project...'
  gcloud source repos create spinnaker-for-gcp-helloworldwebapp
  mkdir -p ~/$PROJECT_ID
  gcloud source repos clone spinnaker-for-gcp-helloworldwebapp ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp
fi

bold 'Adding/Updating Kubernetes config files, sample Go application, and cloud build files in sample repo...'
cp -r templates/repo/config ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/
cp -r templates/repo/src ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/
cp templates/repo/Dockerfile ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/

cat templates/repo/cloudbuild_yaml.template | envsubst '$BUCKET_NAME' > ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/cloudbuild.yaml
cat ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/config/staging/replicaset_yaml.template | envsubst > ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/config/staging/replicaset.yaml
rm ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/config/staging/replicaset_yaml.template
cat ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/config/prod/replicaset_yaml.template | envsubst > ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/config/prod/replicaset.yaml
rm ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp/config/prod/replicaset_yaml.template

pushd ~/$PROJECT_ID/spinnaker-for-gcp-helloworldwebapp

git add *
git commit -m "Add source, build, and manifest files."
git push

popd

bold "Configuring Kubernetes services for prod and staging..."
kubectl apply -f templates/repo/config/staging/service.yaml
kubectl apply -f templates/repo/config/prod/service.yaml

if [ -z $(gcloud alpha builds triggers list --filter triggerTemplate.repoName=spinnaker-for-gcp-helloworldwebapp --format 'get(id)') ]; then
  bold "Creating Cloud Build build trigger for helloworld app..."
  gcloud alpha builds triggers create cloud-source-repositories \
    --repo spinnaker-for-gcp-helloworldwebapp \
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
