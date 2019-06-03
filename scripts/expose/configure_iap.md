# Expose Spinnaker

### Configure OAuth consent screen

Go to the [OAuth consent screen](https://console.developers.google.com/apis/credentials/consent?project=$PROJECT_ID).

Enter an *Application name* (e.g. My Spinnaker), enter your *Email address*, and add **$TOP_PRIVATE_DOMAIN** as an *Authorized domain*.

### Create OAuth credentials

Go to the [Credentials page](https://console.developers.google.com/apis/credentials/oauthclient?project=$PROJECT_ID) and create an *OAuth client ID*.

Use *Application type: Web application*, and add **https://$DOMAIN_NAME/_gcp_gatekeeper/authenticate** as an *Authorized redirect URI*.

Ensure that you note the generated *Client ID* and *Client secret* for your new credentials, as you will need to provide them to the script in the next step.

### Expose Spinnaker and allow for secure access via IAP

```bash
~/spinnaker-for-gcp/scripts/expose/configure_iap.sh
```

This phase could take 30-60 minutes.

## Conclusion

Connect to your Spinnaker installation [here](https://$DOMAIN_NAME).

### View Spinnaker Audit Log

View the who, what, when and where of your Spinnaker installation
[here](https://console.developers.google.com/logs/viewer?project=$PROJECT_ID&resource=cloud_function&logName=projects%2F$PROJECT_ID%2Flogs%2F$CLOUD_FUNCTION_NAME&minLogLevel=200).
