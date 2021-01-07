#!/bin/bash

# Copyright 2020 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

./0.usage.sh 'before-you-begin' 'Before you begin' ${0}
exit

# --- 
# Set up the project

# Create a project. Replace <project-id> placeholder with your own value
export PROJECT_ID=<project-id>
gcloud projects create ${PROJECT_ID}

# Set the project ID in the Cloud SDK properties
gcloud config set project ${PROJECT_ID}

# List the available billing accounts
gcloud alpha billing accounts list

# Enable billing for the project. Replace the <billing-account-id> placeholder by your chosen billing account id.
gcloud alpha billing projects link ${PROJECT_ID} \
  --billing-account <billing-account-id>

# Enable the Cloud APIs for Dataproc, Cloud SQL, and Cloud Key Management Service (KMS)
# [START snippet_010]
gcloud services enable dataproc.googleapis.com sqladmin.googleapis.com \
  cloudkms.googleapis.com
# [END snippet_010]

# In Cloud Shell, set environment variables with the ID your project and the region and zones where the Dataproc clusters will be located
# [START snippet_020]
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export REGION=us-central1
export ZONE=us-central1-b
# [END snippet_020]

# --- 
# Set up a service account

# Create a service account that will be used by the cluster to be authenticated as
# [START snippet_030]
gcloud iam service-accounts create cluster-service-account \
  --description="The service account for the cluster to be authenticated as." \
  --display-name="Cluster service account"
# [END snippet_030]

# Add roles to the service account
# [START snippet_040]
bash -c 'array=( dataproc.worker cloudsql.editor cloudkms.cryptoKeyDecrypter )
for i in "${array[@]}"
do
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:cluster-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role roles/$i
done'
# [END snippet_040]
