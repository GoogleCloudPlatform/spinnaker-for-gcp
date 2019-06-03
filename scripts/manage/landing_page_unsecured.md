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

### Expose Spinnaker

If you would like to connect to Spinnaker without relying on port forwarding, we can
expose it via a secure domain behind the [Identity-Aware Proxy](https://cloud.google.com/iap/).

```bash
~/spinnaker-for-gcp/scripts/expose/configure_endpoint.sh
```
