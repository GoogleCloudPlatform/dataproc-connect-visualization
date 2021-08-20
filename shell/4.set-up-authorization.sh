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

./0.usage.sh 'setting_up_authorization' 'Setting up authorization' ${0}
exit

# ---
# Sync user identities into Ranger

# Connect to the master node of the backend cluster
# [START snippet_420]
export BACKEND_CLUSTER=backend-cluster
gcloud compute ssh --zone ${ZONE} ${BACKEND_CLUSTER}-m
# [END snippet_420]

# Edit the UserSync configuration file
# [START snippet_430]
sudo vi /etc/ranger/usersync/conf/ranger-ugsync-site.xml
# [END snippet_430]

# Set the values of the following LDAP properties
# [START snippet_440]
<property>
  <name>ranger.usersync.sync.source</name>
  <value>ldap</value>
</property>

<property>
  <name>ranger.usersync.ldap.url</name>
  <value>ldap://<proxy-master-internal-dns-name>:33389</value>
</property>

<property>
  <name>ranger.usersync.ldap.binddn</name>
  <value>uid=admin,ou=people,dc=hadoop,dc=apache,dc=org</value>
</property>

<property>
  <name>ranger.usersync.ldap.ldapbindpassword</name>
  <value>admin-password</value>
</property>

<property>
  <name>ranger.usersync.ldap.user.searchbase</name>
  <value>dc=hadoop,dc=apache,dc=org</value>
</property>

<property>
  <name>ranger.usersync.source.impl.class</name>
  <value>org.apache.ranger.ldapusersync.process.LdapUserGroupBuilder</value>
</property>
# [END snippet_440]

# Restart the Ranger UserSync daemon
# [START snippet_450]
sudo service ranger-usersync restart
# [END snippet_450]

# ---
# Create Ranger policies

# Edit the Ranger Hive configuration
# [START snippet_460]
sudo vi /etc/hive/conf/ranger-hive-security.xml
# [END snippet_460]

# Edit the <value> of the ranger.plugin.hive.service.name property
# [START snippet_470]
<property>
  <name>ranger.plugin.hive.service.name</name>
  <value>ranger-hive-service-01</value>
  <description>
    Name of the Ranger service containing policies for this YARN instance
  </description>
</property>
# [END snippet_470]

# Restart the HiveServer2 Admin service
# [START snippet_480]
sudo service hive-server2 restart
# [END snippet_480]

# Enter the Beeline CLI with the user “sara”
# [START snippet_490]
beeline -u "jdbc:hive2://localhost:10000/;transportMode=http;httpPath=cliservice sara user-password"
# [END snippet_490]

# Run the following query to verify it is blocked by Ranger
# [START snippet_500]
SELECT *
  FROM transactions
  LIMIT 10;
# [END snippet_500]

# Run the following query to verify it is allowed by Ranger
# [START snippet_510]
SELECT submissionDate, transactionType
  FROM transactions
  LIMIT 10;
# [END snippet_510]

# Exit the Beeline CLI
# [START snippet_513]
!quit
# [END snippet_513]

# Exit the SSH command line
# [START snippet_516]
exit
# [END snippet_516]

