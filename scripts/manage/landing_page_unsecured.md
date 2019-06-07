## Use Spinnaker

### Forward Port to Deck

```bash
~/spinnaker-for-gcp/scripts/manage/connect_unsecured.sh
```

### Connect to Deck

<walkthrough-spotlight-pointer
    spotlightId="devshell-web-preview-button"
    text="Connect to Spinnaker via 'Preview on port 8080'">
</walkthrough-spotlight-pointer>

### View Spinnaker Audit Log

View the who, what, when and where of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=cloud_function&logName=projects%2F{{project-id}}%2Flogs%2F$CLOUD_FUNCTION_NAME&minLogLevel=200).

### View Spinnaker Container Logs

View the logging output of the individual components of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=k8s_container%2Fcluster_name%2F$GKE_CLUSTER%2Fnamespace_name%2Fspinnaker).

### Expose Spinnaker

If you would like to connect to Spinnaker without relying on port forwarding, we can
expose it via a secure domain behind the [Identity-Aware Proxy](https://cloud.google.com/iap/).

Note that this phase could take 30-60 minutes. **Spinnaker will be inaccessible during this time.**

```bash
~/spinnaker-for-gcp/scripts/expose/configure_endpoint.sh
```

## Delete Spinnaker

### Generate a script to delete all the resources that were provisioned as part of your Spinnaker installation

```bash
~/spinnaker-for-gcp/scripts/manage/generate_deletion_script.sh
```
