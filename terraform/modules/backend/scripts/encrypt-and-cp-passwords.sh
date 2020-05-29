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
# This local script encrypts passwords and copies the encrypted
# files into a bucket

printf '\nEncrypting passwords\n'
printf '%s\n' -------------------

echo ${RANGER_ADMIN_PASSWORD} | \
gcloud kms encrypt \
  --project=${PROJECT_ID} \
  --location=global \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=- \
  --ciphertext-file=ranger-admin-password.encrypted

echo ${RANGER_DB_ADMIN_PASSWORD} | \
gcloud kms encrypt \
  --project=${PROJECT_ID} \
  --location=global \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=- \
  --ciphertext-file=ranger-db-admin-password.encrypted

echo ${MYSQL_ROOT_PASSWORD} | \
gcloud kms encrypt \
  --project=${PROJECT_ID} \
  --location=global \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=- \
  --ciphertext-file=mysql-root-password.encrypted

gsutil -m cp *.encrypted gs://${PROJECT_ID}-ranger
rm *.encrypted