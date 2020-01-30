#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

echo "Please enter the member you wish to grant the 'IAP-secured Web App User' role."
echo "Note that you must include the correct prefix depending on the type of member."
echo "These are the supported types: "
echo "  user:some-user@somedomain.net, serviceAccount:some-service-account@some-project.iam.gserviceaccount.com, group:some-group@somedomain.net, domain:somedomain.net"
read -p "Member to add: " MEMBER_TO_ADD
echo

pushd ~/cloudshell_open/spinnaker-for-gcp/scripts/install

source ./properties

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

source ~/cloudshell_open/spinnaker-for-gcp/scripts/expose/set_iap_properties.sh

gcurl() {
  curl -s -H "Authorization:Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -H "X-Goog-User-Project: $PROJECT_ID" $*
}

bold "Querying for existing IAM policy..."

export EXISTING_IAM_POLICY=$(gcurl -X POST -d "{"options":{"requested_policy_version":3}}" \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:getIamPolicy)

if [ "$(echo $EXISTING_IAM_POLICY | grep "\"$MEMBER_TO_ADD\"")" ]; then
  bold "Member $MEMBER_TO_ADD already has the 'IAP-secured Web App User' role."
  exit 1
fi

UPDATED_IAM_POLICY=$(echo "{}" \
  | jq --argjson existing_policy "$EXISTING_IAM_POLICY" '. += {"policy":$existing_policy}' \
  | jq ".policy.bindings[0].members += [\"$MEMBER_TO_ADD\"]")

bold "Granting member $MEMBER_TO_ADD the 'IAP-secured Web App User' role..."

echo $UPDATED_IAM_POLICY | gcurl -X POST -d @- \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:setIamPolicy

popd
