~/hal/hal config security api edit --override-base-url https://$DOMAIN_NAME/gate
~/hal/hal config security ui edit --override-base-url https://$DOMAIN_NAME
~/hal/hal config security authn iap edit --audience $AUD_CLAIM
~/hal/hal config security authn iap enable
