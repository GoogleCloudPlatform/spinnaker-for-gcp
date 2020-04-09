#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

if [ "$CI" == true ]; then
  HAL_PARENT_DIR=$PARENT_DIR
else
  HAL_PARENT_DIR=$HOME
fi

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/spinnaker-for-gcp/scripts/install/properties"

$PARENT_DIR/spinnaker-for-gcp/scripts/manage/check_duplicate_dirs.sh || exit 1
$PARENT_DIR/spinnaker-for-gcp/scripts/manage/check_git_config.sh || exit 1

source "$PROPERTIES_FILE"

# TODO(duftler): Add check to ensure that we are not overriding with older or empty config.

CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$?" != "0" ]; then
  bold "No current Kubernetes context is configured."
  exit 1
fi

CURRENT_CONTEXT_PROJECT=$(echo $CURRENT_CONTEXT | cut -d '_' -f 2)
CURRENT_CONTEXT_ZONE=$(echo $CURRENT_CONTEXT | cut -d '_' -f 3)
CURRENT_CONTEXT_CLUSTER=$(echo $CURRENT_CONTEXT | cut -d '_' -f 4)

if [ $CURRENT_CONTEXT_PROJECT != $PROJECT_ID ]; then
  bold "Your Spinnaker config references project $PROJECT_ID, but you are connected to a cluster in project $CURRENT_CONTEXT_PROJECT."
  bold "Use 'kubectl config use-context' to connect to the correct cluster before pushing the config."
  exit 1
fi

if [ $CURRENT_CONTEXT_ZONE != $ZONE ]; then
  bold "Your Spinnaker config references zone $ZONE, but you are connected to a cluster in zone $CURRENT_CONTEXT_ZONE."
  bold "Use 'kubectl config use-context' to connect to the correct cluster before pushing the config."
  exit 1
fi

if [ $CURRENT_CONTEXT_CLUSTER != $GKE_CLUSTER ]; then
  bold "Your Spinnaker config references cluster $GKE_CLUSTER, but you are connected to cluster $CURRENT_CONTEXT_CLUSTER."
  bold "Use 'kubectl config use-context' to connect to the correct cluster before pushing the config."
  exit 1
fi

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/cluster_utils.sh

CLUSTER_EXISTS=$(check_for_existing_cluster)

if [ -z "$CLUSTER_EXISTS" ]; then
  bold "Cluster $GKE_CLUSTER cannot be found. It may not exist."
  bold "To recreate your installation with this config, run:"
  bold "USE_CLOUD_SHELL_HAL_CONFIG=true $PARENT_DIR/spinnaker-for-gcp/scripts/install/setup.sh"
  exit 1
fi

if [ -z "$CONFIG_CSR_REPO" ]; then
  bold "CONFIG_CSR_REPO was not set. Please run the $PARENT_DIR/spinnaker-for-gcp/scripts/manage/update_management_environment.sh" \
       "command to ensure you have all the necessary properties declared."
  exit 1
fi

HALYARD_POD=spin-halyard-0

TEMP_DIR=$(mktemp -d -t halyard.XXXXX)
pushd $TEMP_DIR

EXISTING_CSR_REPO=$(gcloud source repos list --format="value(name)" --filter="name=projects/$PROJECT_ID/repos/$CONFIG_CSR_REPO" --project=$PROJECT_ID)

if [ -z "$EXISTING_CSR_REPO" ]; then
  bold "Creating Cloud Source Repository $CONFIG_CSR_REPO..."

  gcloud source repos create $CONFIG_CSR_REPO --project=$PROJECT_ID
fi

gcloud source repos clone $CONFIG_CSR_REPO --project=$PROJECT_ID
cd $CONFIG_CSR_REPO

bold "Backing up $HAL_PARENT_DIR/.hal..."

rm -rf .hal
mkdir .hal

# We want just these subdirs within $HAL_PARENT_DIR/.hal to be copied into place on the Halyard Daemon pod.
DIRS=(credentials profiles service-settings)

for p in "${DIRS[@]}"; do
  for f in $(find $HAL_PARENT_DIR/.hal/*/$p -prune 2> /dev/null); do
    SUB_PATH=$(echo $f | rev | cut -d '/' -f 1,2 | rev)
    mkdir -p .hal/$SUB_PATH
    cp -RT $HAL_PARENT_DIR/.hal/$SUB_PATH .hal/$SUB_PATH
  done
done

cp $HAL_PARENT_DIR/.hal/config .hal

# Please note, rewritable key paths are in both push_config.sh and restore_config_utils.sh
REWRITABLE_KEYS=(kubeconfigFile jsonPath jsonKey passwordFile path templatePath tokenFile \
                 usernamePasswordFile sshPrivateKeyFilePath sshKnownHostsFilePath trustStore credentialPath)
for k in "${REWRITABLE_KEYS[@]}"; do
  grep $k .hal/config &> /dev/null
  FOUND_TOKEN=$?

  if [ "$FOUND_TOKEN" == "0" ]; then
    bold "Rewriting $k path to reflect user 'spinnaker' on Halyard Daemon pod..."
    sed -i "s/$k: \/home\/$USER/$k: \/home\/spinnaker/" .hal/config
  fi
done

bold "Backing up Spinnaker deployment config files..."

rm -rf deployment_config_files
mkdir deployment_config_files

copy_if_exists() {
  if [ -e $1 ]; then
    # If a filter token was passed, only copy the file if the token is present in the source file.
    if [ $3 ]; then
      if [ "$(grep $3 $1)" ]; then
        cp $1 $2
      fi
    else
      cp $1 $2
    fi
  fi
}

copy_if_exists "$PROPERTIES_FILE" deployment_config_files
copy_if_exists $PARENT_DIR/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/config.json deployment_config_files
copy_if_exists $PARENT_DIR/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/index.js deployment_config_files

# These files are generated when Spinnaker is exposed via IAP.
# If the operator is managing more than one installation we don't want to inadvertently backup files from the wrong installation.
copy_if_exists $PARENT_DIR/spinnaker-for-gcp/scripts/expose/configure_iap_expanded.md deployment_config_files "$PROJECT_ID\."
copy_if_exists $PARENT_DIR/spinnaker-for-gcp/scripts/expose/openapi_expanded.yml deployment_config_files "$PROJECT_ID\."
copy_if_exists ~/.spin/config deployment_config_files "$PROJECT_ID\."
copy_if_exists ~/.spin/config deployment_config_files "localhost\:"
copy_if_exists ~/.spin/key.json deployment_config_files "$PROJECT_ID\."

# Remove old persistent config so new config can be copied into place.
bold "Removing halyard/$HALYARD_POD:/home/spinnaker/.hal..."
kubectl -n halyard exec $HALYARD_POD -- bash -c "rm -rf ~/.hal/*"

# Copy new config into place.
bold "Copying $HAL_PARENT_DIR/.hal into halyard/$HALYARD_POD:/home/spinnaker/.hal..."

kubectl -n halyard cp $TEMP_DIR/$CONFIG_CSR_REPO/.hal spin-halyard-0:/home/spinnaker

EXISTING_DEPLOYMENT_SECRET_NAME=$(kubectl get secret -n halyard \
  --field-selector metadata.name=="spinnaker-deployment" \
  -o json | jq .items[0].metadata.name)

if [ $EXISTING_DEPLOYMENT_SECRET_NAME != 'null' ]; then
  bold "Deleting Kubernetes secret spinnaker-deployment..."
  kubectl delete secret spinnaker-deployment -n halyard
fi

bold "Creating Kubernetes secret spinnaker-deployment containing Spinnaker deployment config files..."
kubectl create secret generic spinnaker-deployment -n halyard \
  --from-file deployment_config_files

git add .
git commit -m 'Automated backup.'
git push

popd
rm -rf $TEMP_DIR
