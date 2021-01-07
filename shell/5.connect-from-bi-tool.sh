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

./0.usage.sh 'connecting_from_a_bi_tool' 'Connecting from a BI Tool' ${0}
exit

# ---
# Create a firewall rule

# Create a firewall rule that opens TCP port 8443
# [START snippet_520]
gcloud compute firewall-rules create allow-knox\
  --project=${PROJECT_ID} --direction=INGRESS --priority=1000 \
  --network=default --action=ALLOW --rules=tcp:8443 \
  --target-tags=knox-gateway \
  --source-ranges=<your-public-ip>/32
# [END snippet_520]

# Apply the network tag from the firewall rule to the proxy cluster master node
# [START snippet_530]
gcloud compute instances add-tags ${PROXY_CLUSTER}-m --zone=${ZONE} \
  --tags=knox-gateway
# [END snippet_530]

# ---
# Create an SSH tunnel

# Generate the command to create the tunnel
# [START snippet_550]
echo "gcloud compute ssh ${PROXY_CLUSTER}-m \
  --project ${PROJECT_ID} \
  --zone ${ZONE} \
  -- -L 8443:localhost:8443"
# [END snippet_550]

# ---
# Query Hive data

# Enter the following query
# [START snippet_560]
SELECT `submissiondate`,
       `transactiontype`
FROM `default`.`transactions`
# [END snippet_560]

# Enter the following query
# [START snippet_570]
SELECT *
FROM `default`.`transactions`
# [END snippet_570]

