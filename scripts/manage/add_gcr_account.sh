#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties

read -e -p "Please enter the id of the project within which you wish to manage GCR resources: " -i $PROJECT_ID MANAGED_PROJECT_ID
read -e -p "Please enter a name for the new Spinnaker account: " -i "$MANAGED_PROJECT_ID-acct" GCR_ACCOUNT_NAME
read -e -p "Please enter address for GCR images: " -i "gcr.io" GCR_ADRESS

bold "Assigning required roles to $SERVICE_ACCOUNT_NAME..."

SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')

GCR_REQUIRED_ROLES=(storage.admin browser)
EXISTING_ROLES=$(gcloud projects get-iam-policy --filter bindings.members:$SA_EMAIL $MANAGED_PROJECT_ID \
  --flatten bindings[].members --format="value(bindings.role)")

if [ "$?" != "0" ]; then
    bold "$USER does not have permission to query IAM policy on project $MANAGED_PROJECT_ID." \
         "Please grant the necessary permissions and re-run this command."
    exit 1
fi

for r in "${GCR_REQUIRED_ROLES[@]}"; do
  if [ -z "$(echo $EXISTING_ROLES | grep $r)" ]; then
    bold "Assigning role $r in project $MANAGED_PROJECT_ID to service account $SA_EMAIL..."
    gcloud projects add-iam-policy-binding $MANAGED_PROJECT_ID \
      --member serviceAccount:$SA_EMAIL \
      --role roles/$r \
      --format=none

    if [ "$?" != "0" ]; then
      bold "$USER does not have permission to assign role $r on project $MANAGED_PROJECT_ID." \
           "Please grant the necessary permissions and re-run this command."
      exit 1
    fi
  fi
done

GCR_SERVICE_ACCOUNT_DEST=".hal/default/credentials/gcr-account-$MANAGED_PROJECT_ID.json"

bold "Storing JSON secret key to $GCR_SERVICE_ACCOUNT_DEST for $SERVICE_ACCOUNT_NAME"

mkdir -p $(dirname $GCR_SERVICE_ACCOUNT_DEST)
gcloud iam service-accounts keys create $GCR_SERVICE_ACCOUNT_DEST \
    --iam-account $SA_EMAIL


~/hal/hal config provider docker-registry enable
~/hal/hal config provider docker-registry account add $GCR_ACCOUNT_NAME --address $GCR_ADRESS --username _json_key --password-file $GCR_SERVICE_ACCOUNT_DEST

bold "Remember that your configuration changes have only been made locally."
bold "They must be pushed and applied to your deployment to take effect:"
bold "  ~/spinnaker-for-gcp/scripts/manage/push_and_apply.sh"
