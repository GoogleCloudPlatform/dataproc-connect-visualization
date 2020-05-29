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
# This local script configures the Ranger UserSync daemon in the
# Banckend cluster to sync the identities from the same directory 
# that Knox is using. 


set -euxo pipefail

cd ${MODULE_PATH}/scripts
cp ranger-ugsync-site.xml ranger-ugsync-site.new.xml

# Replace placeholder with the actual backend master DNS name
sed -i'.bak' -e "s/backend-master-internal-dns-name/${BACKEND_CLUSTER_NAME}-m.${ZONE}.c.${PROJECT_ID}.internal/" ranger-ugsync-site.new.xml

# Replace placeholder with the actual proxy master DNS name
sed -i'.bak' -e "s/proxy-master-internal-dns-name/${PROXY_CLUSTER_NAME}-m.${ZONE}.c.${PROJECT_ID}.internal/" ranger-ugsync-site.new.xml

echo "Copy UserSync XML config into backend master"
gcloud compute scp \
  ranger-ugsync-site.new.xml \
  ${BACKEND_CLUSTER_NAME}-m:~/ranger-ugsync-site.xml \
  --project=${PROJECT_ID} \
  --zone=${ZONE} 

echo "Move file with sudo to Ranger UserSync directory"
RANGER_CONF_DIR='/etc/ranger/usersync/conf'
gcloud compute ssh ${BACKEND_CLUSTER_NAME}-m \
  --command="sudo cp ${RANGER_CONF_DIR}/ranger-ugsync-site.xml ${RANGER_CONF_DIR}/ranger-ugsync-site.bak.xml; \
             sudo mv ~/ranger-ugsync-site.xml ${RANGER_CONF_DIR} \
             && sudo service ranger-usersync restart" \
  --project=${PROJECT_ID} \
  --zone=${ZONE} 

# No side effects
rm ranger-ugsync-site.new.*