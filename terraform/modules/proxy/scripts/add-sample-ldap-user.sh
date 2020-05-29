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
# This init action adds a sample user to the LDAP store on the 
# Proxy cluster


set -euxo pipefail

# Run only in the master
ROLE=$(/usr/share/google/get_metadata_value attributes/dataproc-role)
if [[ "${ROLE}" == 'Master' ]]; then
  sudo apt-get -y install ldap-utils

  USER_ID=sara
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

  ldapadd -f new-user.ldif \
    -D 'uid=admin,ou=people,dc=hadoop,dc=apache,dc=org' \
    -w 'admin-password' \
    -H ldap://localhost:33389
fi