#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

CURRENT_K8S_CONTEXT=$(kubectl config current-context)
AVAILABLE_K8S_CONTEXTS=$(kubectl config get-contexts -o name)

echo "Available contexts:"
echo "$AVAILABLE_K8S_CONTEXTS"
echo

if [ -z $CURRENT_K8S_CONTEXT ]; then
  read -e -p "Please enter the context you wish to use to manage your GKE resources: " TARGET_K8S_CONTEXT
else
  read -e -p "Please enter the context you wish to use to manage your GKE resources: " -i $CURRENT_K8S_CONTEXT TARGET_K8S_CONTEXT
fi

FOUND_CONTEXT=$(echo "$AVAILABLE_K8S_CONTEXTS" | grep "^$TARGET_K8S_CONTEXT$")

if [ -z $FOUND_CONTEXT ]; then
  bold "$TARGET_K8S_CONTEXT not found in available contexts..."
  exit 1
fi

MANAGED_PROJECT_ID=$(echo $TARGET_K8S_CONTEXT | cut -d _ -f 2)

read -e -p "Please enter the id of the project within which the referenced cluster lives: " -i $MANAGED_PROJECT_ID MANAGED_PROJECT_ID
read -e -p "Please enter a name for the new Spinnaker account: " -i "$(echo $TARGET_K8S_CONTEXT | cut -d _ -f 4)-acct" GKE_ACCOUNT_NAME

bold "Assigning required roles to $SERVICE_ACCOUNT_NAME..."

SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')

GKE_REQUIRED_ROLES=(container.admin)
EXISTING_ROLES=$(gcloud projects get-iam-policy --filter bindings.members:$SA_EMAIL $MANAGED_PROJECT_ID \
  --flatten bindings[].members --format="value(bindings.role)")

if [ "$?" != "0" ]; then
    bold "$USER does not have permission to query IAM policy on project $MANAGED_PROJECT_ID." \
         "Please grant the necessary permissions and re-run this command."
    exit 1
fi

for r in "${GKE_REQUIRED_ROLES[@]}"; do
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

mkdir -p ~/.hal/default/credentials
KUBECONFIG_FILENAME="kubeconfig-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 9 | head -n 1)"

bold "Copying ~/.kube/config into ~/.hal/default/credentials/$KUBECONFIG_FILENAME so it can be pushed to your halyard daemon's pod..."

cp ~/.kube/config ~/.hal/default/credentials/$KUBECONFIG_FILENAME

~/hal/hal config provider kubernetes account add $GKE_ACCOUNT_NAME \
  --provider-version v2 \
  --context $TARGET_K8S_CONTEXT \
  --kubeconfig-file ~/.hal/default/credentials/$KUBECONFIG_FILENAME

bold "Remember that your configuration changes have only been made locally."
bold "They must be pushed and applied to your deployment to take effect:"
bold "  ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_and_apply.sh"
