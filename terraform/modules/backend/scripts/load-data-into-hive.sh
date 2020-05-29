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

# Dataproc init action:
# This init action creates a sample Hive table on the master node of a
# Dataproc cluster.


set -euxo pipefail

# Run only in the master
ROLE=$(/usr/share/google/get_metadata_value attributes/dataproc-role)
if [[ "${ROLE}" == 'Master' ]]; then

  readonly PROJECT_ID="$(/usr/share/google/get_metadata_value ../project/project-id)"

  echo "Copy a publicly available sample Parquet file into bucket gs://${PROJECT_ID}-hive"
  gsutil cp gs://hive-solution/part-00000.parquet \
    gs://${PROJECT_ID}-hive/dataset/transactions/part-00000.parquet

  echo 'Load transaction data into Hive'
  beeline -u "jdbc:hive2://localhost:10000/;transportMode=http;httpPath=cliservice admin admin-password"\
    --hivevar PROJECT_ID=${PROJECT_ID}\
    -e 'CREATE EXTERNAL TABLE transactions
    (SubmissionDate DATE, TransactionAmount DOUBLE, TransactionType STRING)
    STORED AS PARQUET
    LOCATION "gs://${PROJECT_ID}-hive/dataset/transactions";'

  echo 'Done'
fi
