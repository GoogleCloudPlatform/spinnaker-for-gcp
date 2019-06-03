#!/bin/bash
#
# Would expect this to be deleted once these tests are properly integrated with GCP Marketplace Verification Pipeline.

if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID=$(gcloud info --format='value(config.project)')
fi

export PROJECT_ID

docker build -t gcr.io/$PROJECT_ID/spinnaker-c2d-tests .

docker push gcr.io/$PROJECT_ID/spinnaker-c2d-tests:latest

kubectl delete job spinnaker-test-job

envsubst < spinnaker-test-job.yaml | kubectl apply -f -

kubectl wait --for condition=complete job spinnaker-test-job

kubectl logs -l job-name=spinnaker-test-job
