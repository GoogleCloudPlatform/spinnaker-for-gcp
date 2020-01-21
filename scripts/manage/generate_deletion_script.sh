#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

bold "Generating deletion script for $DEPLOYMENT_NAME in cluster $GKE_CLUSTER of project $PROJECT_ID..."

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

DELETION_SCRIPT_FILENAME="$HOME/cloudshell_open/spinnaker-for-gcp/scripts/manage/delete-all_${PROJECT_ID}_${GKE_CLUSTER}_${DEPLOYMENT_NAME}.sh"

SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')

cat > $DELETION_SCRIPT_FILENAME <<EOL
#!/usr/bin/env bash

# Ensure that you comment out the deletion commands for resources you'd rather not delete.

bold() {
  echo ". \$(tput bold)" "\$*" "\$(tput sgr0)";
}

bold "Deleting cluster $GKE_CLUSTER in $PROJECT_ID..."
gcloud container clusters delete $GKE_CLUSTER --zone $ZONE --project $PROJECT_ID

bold "Deleting bucket $BUCKET_URI..."
gsutil rm -r $BUCKET_URI

bold "Deleting Cloud Source Repository $CONFIG_CSR_REPO..."
gcloud source repos delete $CONFIG_CSR_REPO --project=$PROJECT_ID

bold "Deleting subscription $GCR_PUBSUB_SUBSCRIPTION in $PROJECT_ID..."
gcloud pubsub subscriptions delete $GCR_PUBSUB_SUBSCRIPTION --project $PROJECT_ID

bold "Deleting subscription $GCB_PUBSUB_SUBSCRIPTION in $PROJECT_ID..."
gcloud pubsub subscriptions delete $GCB_PUBSUB_SUBSCRIPTION --project $PROJECT_ID

bold "Deleting cloud function $CLOUD_FUNCTION_NAME in $PROJECT_ID..."
gcloud functions delete $CLOUD_FUNCTION_NAME --region $REGION --project $PROJECT_ID

bold "Deleting redis instance $REDIS_INSTANCE in $NETWORK_PROJECT..."
gcloud redis instances delete $REDIS_INSTANCE --region $REGION --project $NETWORK_PROJECT
EOL

if [ "$SA_EMAIL" ]; then
  EXISTING_ROLES=($(gcloud projects get-iam-policy --filter bindings.members:$SA_EMAIL $PROJECT_ID \
    --flatten bindings[].members --format="value(bindings.role)"))

  for r in "${EXISTING_ROLES[@]}"; do
    cat >> $DELETION_SCRIPT_FILENAME <<EOL

bold "Deleting IAM policy binding for role $r from $SA_EMAIL in $PROJECT_ID..."
gcloud projects remove-iam-policy-binding $PROJECT_ID --member serviceAccount:$SA_EMAIL --role $r
EOL
  done

  cat >> $DELETION_SCRIPT_FILENAME <<EOL

bold "Deleting service account $SA_EMAIL in $PROJECT_ID..."
gcloud iam service-accounts delete $SA_EMAIL --project $PROJECT_ID
EOL
fi

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ "$IP_ADDR" ]; then

  cat >> $DELETION_SCRIPT_FILENAME <<EOL

bold "Deleting static IP address $STATIC_IP_NAME in $PROJECT_ID..."
gcloud compute addresses delete $STATIC_IP_NAME --global --project $PROJECT_ID

bold "Deleting managed SSL certificate $MANAGED_CERT in project $PROJECT_ID..."
gcloud beta compute ssl-certificates delete $MANAGED_CERT --global --project $PROJECT_ID

bold "Deleting service endpoint $DOMAIN_NAME in project $PROJECT_ID..."
gcloud endpoints services delete $DOMAIN_NAME --project $PROJECT_ID

bold "Ensure that you manually delete your OAuth Client ID here: https://console.developers.google.com/apis/credentials?project=$PROJECT_ID"
EOL
fi

chmod +x $DELETION_SCRIPT_FILENAME

echo
bold "Use this command to delete all the resources that were provisioned as part of your Spinnaker installation:"
bold "  $DELETION_SCRIPT_FILENAME"

echo
bold "Warning: If you installed Spinnaker on pre-existing infrastructure (GKE cluster, Redis, service accounts, ...)," \
     "this script deletes them. If you want to keep them, edit the generated cleanup script $DELETION_SCRIPT_FILENAME" \
     "to comment out the specific deletion commands for items you want to keep:"
bold "  cloudshell edit $DELETION_SCRIPT_FILENAME"
