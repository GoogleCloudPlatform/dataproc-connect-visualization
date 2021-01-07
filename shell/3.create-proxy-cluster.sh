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

./0.usage.sh 'creating_the_proxy_cluster' 'Creating the proxy cluster' ${0}
exit

# ---
# Create a topology

# Clone the Dataproc initialization-actions GitHub repository
# [START snippet_260]
git clone https://github.com/GoogleCloudDataproc/initialization-actions.git
# [END snippet_260]

# Create a topology for the backend cluster
# [START snippet_270]
export KNOX_INIT_FOLDER=`pwd`/initialization-actions/knox
cd ${KNOX_INIT_FOLDER}/topologies/
mv example-hive-nonpii.xml hive-us-transactions.xml
# [END snippet_270]

# Edit the topology file
# [START snippet_280]
vi hive-us-transactions.xml
# [END snippet_280]

# Add the data analyst sample LDAP user identity “sara”
# [START snippet_290]
<param>
   <name>hive.acl</name>
   <value>admin,sara;*;*</value>
</param>
# [END snippet_290]

# Change the HIVE url to point to the backend cluster Hive service
# [START snippet_300]
<service>
  <role>HIVE</role>
  <url>http://<backend-master-internal-dns-name>:10000/cliservice</url>
</service>
# [END snippet_300]

# ---
# Configure the SSL/TLS certificate

# Edit the Apache Knox general configuration file
# [START snippet_310]
vi ${KNOX_INIT_FOLDER}/knox-config.yaml
# [END snippet_310]

# Replace HOSTNAME by the external DNS name of your master node
# [START snippet_320]
certificate_hostname: localhost
# [END snippet_320]

# --- 
# Spin up the proxy cluster

# Create a Cloud Storage bucket to provide the configurations
# [START snippet_330]
gsutil mb -l ${REGION} gs://${PROJECT_ID}-knox
# [END snippet_330]

# Copy all the files from the Knox initialization action folder into the bucket
# [START snippet_340]
gsutil -m cp -r ${KNOX_INIT_FOLDER}/* gs://${PROJECT_ID}-knox
# [END snippet_340]

# Export all the variables required to create the cluster
# [START snippet_350]
export PROXY_CLUSTER=proxy-cluster
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export REGION=us-central1
export ZONE=us-central1-b
# [END snippet_350]

# Create the proxy cluster
# [START snippet_360]
gcloud dataproc clusters create ${PROXY_CLUSTER} \
  --region ${REGION} \
  --zone ${ZONE} \
  --service-account=cluster-service-account@${PROJECT_ID}.iam.gserviceaccount.com \
  --initialization-actions gs://goog-dataproc-initialization-actions-${REGION}/knox/knox.sh \
  --metadata knox-gw-config=gs://${PROJECT_ID}-knox
# [END snippet_360]

# ---
# Verify connection through proxy

# Connect to its master node using SSH
# [START snippet_370]
gcloud compute ssh --zone ${ZONE} ${PROXY_CLUSTER}-m
# [END snippet_370]

# Run a query 
# [START snippet_380]
beeline -u "jdbc:hive2://localhost:8443/;\
ssl=true;sslTrustStore=/usr/lib/knox/data/security/keystores/gateway-client.jks;trustStorePassword=secret;\
transportMode=http;httpPath=gateway/hive-us-transactions/hive"\
  -e "SELECT SubmissionDate, TransactionType FROM transactions LIMIT 10;"\
  -n admin -p admin-password
# [END snippet_380]

# --
# Add user to authentication store

# Install the LDAP utils
# [START snippet_390]
sudo apt-get install ldap-utils
# [END snippet_390]

# Create an LDAP Data Interchange Format (LDIF) file
# [START snippet_400]
export USER_ID=sara

printf '%s\n'\
  "# entry for user ${USER_ID}"\
  "dn: uid=${USER_ID},ou=people,dc=hadoop,dc=apache,dc=org"\
  "objectclass:top"\
  "objectclass:person"\
  "objectclass:organizationalPerson"\
  "objectclass:inetOrgPerson"\
  "cn: ${USER_ID}"\
  "sn: ${USER_ID}"\
  "uid: ${USER_ID}"\
  "userPassword:${USER_ID}-password"\
> new-user.ldif
# [END snippet_400]

# Add the user ID to the LDAP directory
# [START snippet_405]
ldapadd -f new-user.ldif \
  -D 'uid=admin,ou=people,dc=hadoop,dc=apache,dc=org' \
  -w 'admin-password' \
  -H ldap://localhost:33389
# [END snippet_405]

# Verify that the new user was added
# [START snippet_410]
ldapsearch -b "uid=${USER_ID},ou=people,dc=hadoop,dc=apache,dc=org" \
  -D 'uid=admin,ou=people,dc=hadoop,dc=apache,dc=org' \
  -w 'admin-password' \
  -H ldap://localhost:33389
# [END snippet_410]

# Take note of the internal DNS name of the proxy master
# [START snippet_413]
hostname -A | tr -d '[:space:]'; echo
# [END snippet_413]

# Exit the SSH command line
# [START snippet_416]
exit
# [END snippet_416]
