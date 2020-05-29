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

# Local script:
# This local script clones the Knox init action, configures a topology,
# configures the certificate and uploads the init action files to a bucket

set -euxo pipefail

# --------------------
# Download init action
# --------------------
rm -fr initialization-actions
git clone https://github.com/GoogleCloudDataproc/initialization-actions.git
START_DIR=`pwd`
KNOX_DIR="${START_DIR}/initialization-actions/knox"

# --------------------
# Configure topology
# --------------------
echo 'Creating Knox topology'
mv "${KNOX_DIR}/topologies/example-hive-nonpii.xml" "${KNOX_DIR}/topologies/hive-us-transactions.xml"

# Add user 'sara' to the hive.acl
# Original:
#				<name>hive.acl</name>
#				<value>admin;*;*</value>
# Modified:
#				<name>hive.acl</name>
#				<value>admin,sara;*;*</value>
sed -i'.bak' -e 's/admin;\*;\*/admin,sara;*;*/g' "${KNOX_DIR}/topologies/hive-us-transactions.xml"

# Replace Hive address with backend cluster internal DNS name
# https://cloud.google.com/compute/docs/internal-dns#instance-fully-qualified-domain-names
# Original:
#		<url>http://localhost:10000/cliservice</url>
# Modified (example):
#		<url>http://backend-cluster-m.us-central1-b.c.project-xyz-tf-05.internal:10000/cliservice</url> 
sed -i'.bak' -e "s~http://.*:10000~http://${BACKEND_CLUSTER_NAME}-m.${ZONE}.c.${PROJECT_ID}.internal:10000~" "${KNOX_DIR}/topologies/hive-us-transactions.xml"

# --------------------
# Configure certificate
# --------------------
echo 'Configuring Knox certificate'
#cd "${KNOX_DIR}"

# Set localhost for the certificate HOSTNAME
# Original:
# certificate_hostname: HOSTNAME
# Modified:
# certificate_hostname: localhost
sed -i'.bak' -e 's/_hostname: HOSTNAME/_hostname: localhost/' "${KNOX_DIR}/knox-config.yaml"

gsutil -m cp -r "${KNOX_DIR}/*" gs://${PROJECT_ID}-knox

# No side effects
rm -fr initialization-actions