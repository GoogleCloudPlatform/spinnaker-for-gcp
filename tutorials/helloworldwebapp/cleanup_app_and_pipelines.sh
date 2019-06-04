#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

cd ~/spinnaker-for-gcp/

source scripts/install/properties

scripts/manage/check_project_mismatch.sh

read -p ". $(tput bold)You are about to delete all resources from the helloworldwebapp application and pipelines. This step is not reversible. Do you wish to continue (Y/n)? $(tput sgr0)" yn
case $yn in
  [Yy]* ) ;;
  "" ) ;;
  * ) exit;;
esac

bold "Deleting CSR repository..."

gcloud source repos delete spinnaker-marketplace-helloworldwebapp
rm -rf ~/$PROJECT_ID/spinnaker-marketplace-helloworldwebapp

bold "Deleting helloworldwebapp-prod and helloworldwebapp-staging Kubernetes resources..."

kubectl delete -f tutorials/helloworldwebapp/templates/csr/config/staging/service.yaml
kubectl delete -f tutorials/helloworldwebapp/templates/csr/config/prod/service.yaml

bold "Deleting Cloud Build trigger..."

for trigger in $(gcloud alpha builds triggers list --filter triggerTemplate.repoName=spinnaker-marketplace-helloworldwebapp --format 'get(id)'); do
  gcloud alpha builds triggers delete -q $trigger
done

bold "Deleting Kubernetes manifests..."

gsutil -m rm -r gs://$BUCKET_NAME/helloworldwebapp-manifests

bold "Deleting GCR images..."

for digest in $(gcloud container images list-tags gcr.io/${PROJECT_ID}/spinnaker-marketplace-helloworldwebapp --format='get(digest)'); do
  gcloud container images delete -q --force-delete-tags "gcr.io/${PROJECT_ID}/spinnaker-marketplace-helloworldwebapp@${digest}"
done

bold "Deleting Spinnaker helloworldwebapp application and pipelines..."

set -x
~/spin pipeline delete -a helloworldwebapp -n "Deploy to Staging"
~/spin pipeline delete -a helloworldwebapp -n "Deploy to Production"
~/spin application delete helloworldwebapp
{ set +x ;} 2> /dev/null

bold "Finished cleaning up helloworldwebapp resources."
