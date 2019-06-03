## Configure User Access (IAP)

```bash
~/spinnaker-for-gcp/scripts/manage/grant_iap_access.sh
```

Alternatively, you can manually grant the `IAP-secured Web App User` role on the `spinnaker/spin-deck` resource to the user you'd like to grant access to [here](https://console.developers.google.com/security/iap?project={{project-id}}).

## Use Spinnaker

### Connect to Spinnaker

Connect to your Spinnaker installation [here](https://$DOMAIN_NAME).

### View Spinnaker Audit Log

View the who, what, when and where of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project={{project-id}}&resource=cloud_function&logName=projects%2F{{project-id}}%2Flogs%2F$CLOUD_FUNCTION_NAME&minLogLevel=200).
