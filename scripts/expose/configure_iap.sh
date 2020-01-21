#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

pushd ~/cloudshell_open/spinnaker-for-gcp/scripts

source ./install/properties

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

EXISTING_SECRET_NAME=$(kubectl get secret -n spinnaker \
  --field-selector metadata.name=="$SECRET_NAME" \
  -o json | jq .items[0].metadata.name)

if [ $EXISTING_SECRET_NAME == 'null' ]; then
  bold "Creating Kubernetes secret $SECRET_NAME..."

  read -p 'Enter your OAuth credentials Client ID: ' CLIENT_ID
  read -p 'Enter your OAuth credentials Client secret: ' CLIENT_SECRET

  cat >~/.spin/config <<EOL
gate:
  endpoint: https://$DOMAIN_NAME/gate

auth:
  enabled: true
  iap:
    # check detailed config in https://cloud.google.com/iap/docs/authentication-howto#authenticating_from_a_desktop_app
    iapClientId: $CLIENT_ID
    serviceAccountKeyPath: "$HOME/.spin/key.json"
EOL
  SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
    --filter="displayName:$SERVICE_ACCOUNT_NAME" \
    --format='value(email)')

  gcloud iam service-accounts keys create ~/.spin/key.json \
    --iam-account $SA_EMAIL \
    --project $PROJECT_ID

  kubectl create secret generic $SECRET_NAME -n spinnaker --from-literal=client_id=$CLIENT_ID \
    --from-literal=client_secret=$CLIENT_SECRET
else
  bold "Using existing Kubernetes secret $SECRET_NAME..."
fi

envsubst < expose/backend-config.yml | kubectl apply -f -

# Associate deck service with backend config.
kubectl patch svc -n spinnaker spin-deck --patch \
  "[{'op': 'add', 'path': '/metadata/annotations/beta.cloud.google.com~1backend-config', \
  'value':'{\"default\": \"config-default\"}'}]" --type json

# Change spin-deck service to NodePort:
DECK_SERVICE_TYPE=$(kubectl get service -n spinnaker spin-deck \
  --output=jsonpath={.spec.type})

if [ $DECK_SERVICE_TYPE != 'NodePort' ]; then
  bold "Patching spin-deck service to be NodePort instead of $DECK_SERVICE_TYPE..."

  kubectl patch service -n spinnaker spin-deck --patch \
    "[{'op': 'replace', 'path': '/spec/type', \
    'value':'NodePort'}]" --type json
else
  bold "Service spin-deck is already NodePort..."
fi

# Create ingress:
bold $(envsubst < expose/deck-ingress.yml | kubectl apply -f -)

source expose/set_iap_properties.sh

gcurl() {
  curl -s -H "Authorization:Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -H "X-Goog-User-Project: $PROJECT_ID" $*
}

export IAP_IAM_POLICY_ETAG=$(gcurl -X POST -d "{"options":{"requested_policy_version":3}}" \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:getIamPolicy | jq .etag)

cat expose/iap_policy.json | envsubst | gcurl -X POST -d @- \
  https://iap.googleapis.com/v1beta1/projects/$PROJECT_NUMBER/iap_web/compute/services/$BACKEND_SERVICE_ID:setIamPolicy

bold "Configuring Spinnaker security settings..."

cat expose/configure_hal_security.sh | envsubst | bash

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_landing_page.sh
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_and_apply.sh

bold "ACTION REQUIRED:"
bold "  - Navigate to: https://console.developers.google.com/apis/credentials/oauthclient/$CLIENT_ID?project=$PROJECT_ID"
bold "  - Add https://iap.googleapis.com/v1/oauth/clientIds/$CLIENT_ID:handleRedirect to your Web client ID as an Authorized redirect URI."

# # What about CORS?

# # Wait for services to come online again (steal logic from setup.sh):

popd
