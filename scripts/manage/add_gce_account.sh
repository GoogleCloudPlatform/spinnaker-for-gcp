#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties

read -e -p "Please enter the id of the project within which you wish to manage GCE resources: " -i $PROJECT_ID MANAGED_PROJECT_ID
read -e -p "Please enter a name for the new Spinnaker account: " -i "$MANAGED_PROJECT_ID-acct" GCE_ACCOUNT_NAME

bold "Assigning required roles to $SERVICE_ACCOUNT_NAME..."

SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')

GCE_REQUIRED_ROLES=(compute.instanceAdmin compute.networkAdmin compute.securityAdmin compute.storageAdmin iam.serviceAccountUser)
EXISTING_ROLES=$(gcloud projects get-iam-policy --filter bindings.members:$SA_EMAIL $MANAGED_PROJECT_ID \
  --flatten bindings[].members --format="value(bindings.role)")

for r in "${GCE_REQUIRED_ROLES[@]}"; do
  if [ -z "$(echo $EXISTING_ROLES | grep $r)" ]; then
    bold "Assigning role $r in project $MANAGED_PROJECT_ID to service account $SA_EMAIL..."
    gcloud projects add-iam-policy-binding $MANAGED_PROJECT_ID \
      --member serviceAccount:$SA_EMAIL \
      --role roles/$r \
      --format=none
  fi
done

~/hal/hal config provider google account add $GCE_ACCOUNT_NAME --project $MANAGED_PROJECT_ID
~/hal/hal config provider google enable
