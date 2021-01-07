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

./0.usage.sh 'creating_the_backend_cluster' 'Creating the backend cluster' ${0}
exit

# ---
# Create the Ranger database instance

# Create a MySQL instance to store the Apache Ranger policies
# [START snippet_050]
export CLOUD_SQL_NAME=cloudsql-mysql
gcloud sql instances create ${CLOUD_SQL_NAME} \
  --tier=db-n1-standard-1 --region=${REGION}
# [END snippet_050]

# Set the instance password for the user root connecting from any host
# [START snippet_060]
gcloud sql users set-password root \
  --host=% --instance ${CLOUD_SQL_NAME} --password mysql-root-password-99
# [END snippet_060]

# ---
# Encrypt the passwords

# Create a Key Management Service (KMS) keyring to hold your keys
# [START snippet_070]
gcloud kms keyrings create my-keyring --location global
# [END snippet_070]

# Create a Key Management Service (KMS) cryptographic key to encrypt your passwords
# [START snippet_080]
gcloud kms keys create my-key \
  --location global \
  --keyring my-keyring \
  --purpose encryption
# [END snippet_080]

# Encrypt your Ranger admin user’s password using the key
# [START snippet_090]
echo "ranger-admin-password-99" | \
gcloud kms encrypt \
  --location=global \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=- \
  --ciphertext-file=ranger-admin-password.encrypted
# [END snippet_090]

# Encrypt your Ranger database admin user’s password using the key
# [START snippet_100]
echo "ranger-db-admin-password-99" | \
gcloud kms encrypt \
  --location=global \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=- \
  --ciphertext-file=ranger-db-admin-password.encrypted
# [END snippet_100]

# Encrypt your MySQL root password using the key
# [START snippet_110]
echo "mysql-root-password-99" | \
gcloud kms encrypt \
  --location=global \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=- \
  --ciphertext-file=mysql-root-password.encrypted
# [END snippet_110]

# Create a Cloud Storage bucket to store encrypted password files
# [START snippet_120]
gsutil mb -l ${REGION} gs://${PROJECT_ID}-ranger
# [END snippet_120]

# Upload the encrypted password files to the Cloud Storage bucket.
# [START snippet_130]
gsutil -m cp *.encrypted gs://${PROJECT_ID}-ranger
# [END snippet_130]

# ---
# Create the cluster

# Create a Cloud Storage bucket to store the Apache Solr audit logs
# [START snippet_140]
gsutil mb -l ${REGION} gs://${PROJECT_ID}-solr
# [END snippet_140]

# Export all the variables required to create the cluster
# [START snippet_150]
export BACKEND_CLUSTER=backend-cluster

export PROJECT_ID=$(gcloud info --format='value(config.project)')
export REGION=us-central1
export ZONE=us-central1-b
export CLOUD_SQL_NAME=cloudsql-mysql

export RANGER_KMS_KEY_URI=\
projects/${PROJECT_ID}/locations/global/keyRings/my-keyring/cryptoKeys/my-key

export RANGER_ADMIN_PWD_URI=\
gs://${PROJECT_ID}-ranger/ranger-admin-password.encrypted

export RANGER_DB_ADMIN_PWD_URI=\
gs://${PROJECT_ID}-ranger/ranger-db-admin-password.encrypted

export MYSQL_ROOT_PWD_URI=\
gs://${PROJECT_ID}-ranger/mysql-root-password.encrypted
# [END snippet_150]

# Create the backend Dataproc cluster
# [START snippet_160]
gcloud beta dataproc clusters create ${BACKEND_CLUSTER} \
  --optional-components=SOLR,RANGER \
  --region ${REGION} \
  --zone ${ZONE} \
  --enable-component-gateway \
  --scopes=default,sql-admin \
  --service-account=cluster-service-account@${PROJECT_ID}.iam.gserviceaccount.com \
  --properties="\
dataproc:ranger.kms.key.uri=${RANGER_KMS_KEY_URI},\
dataproc:ranger.admin.password.uri=${RANGER_ADMIN_PWD_URI},\
dataproc:ranger.db.admin.password.uri=${RANGER_DB_ADMIN_PWD_URI},\
dataproc:ranger.cloud-sql.instance.connection.name=${PROJECT_ID}:${REGION}:${CLOUD_SQL_NAME},\
dataproc:ranger.cloud-sql.root.password.uri=${MYSQL_ROOT_PWD_URI},\
dataproc:solr.gcs.path=gs://${PROJECT_ID}-solr,\
hive:hive.server2.thrift.http.port=10000,\
hive:hive.server2.thrift.http.path=cliservice,\
hive:hive.server2.transport.mode=http"
# [END snippet_160]

# ---
# Create a sample Hive table

# Create a Cloud Storage bucket to store a sample Apache Parquet file
# [START snippet_170]
gsutil mb -l ${REGION} gs://${PROJECT_ID}-hive
# [END snippet_170]

# Copy a publicly available sample Parquet file into your bucke
# [START snippet_180]
gsutil cp gs://hive-solution/part-00000.parquet \
  gs://${PROJECT_ID}-hive/dataset/transactions/part-00000.parquet
# [END snippet_180]

# Connect using SSH into the master node
# [START snippet_190]
gcloud compute ssh --zone ${ZONE} ${BACKEND_CLUSTER}-m
# [END snippet_190]

# Once in the SSH command prompt, connect to the local HiveServer2 using Apache Beeline
# [START snippet_200]
beeline -u "jdbc:hive2://localhost:10000/;transportMode=http;httpPath=cliservice admin admin-password"\
  --hivevar PROJECT_ID=$(gcloud info --format='value(config.project)')
# [END snippet_200]

# In the Beeline CLI, create a table using the Parquet file previously copied in your Hive bucket
# [START snippet_210]
CREATE EXTERNAL TABLE transactions
  (SubmissionDate DATE, TransactionAmount DOUBLE, TransactionType STRING)
  STORED AS PARQUET
  LOCATION 'gs://${PROJECT_ID}-hive/dataset/transactions';
# [END snippet_210]

# Verify that the table was created correctly
# [START snippet_220]
SELECT *
  FROM transactions
  LIMIT 10;

SELECT TransactionType, AVG(TransactionAmount) AS AverageAmount
  FROM transactions
  WHERE SubmissionDate = '2017-12-22'
  GROUP BY TransactionType;
# [END snippet_220]

# Exit the Beeline CLI
# [START snippet_230]
!quit
# [END snippet_230]

# Take note of the internal DNS name of the backend master
# [START snippet_240]
hostname -A | tr -d '[:space:]'; echo
# [END snippet_240]

# Exit the SSH command line
# [START snippet_250]
exit
# [END snippet_250]
