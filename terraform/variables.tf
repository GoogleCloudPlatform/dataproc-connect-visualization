/* Copyright 2020 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
/* Copyright 2020 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

variable "project_id" {
  description = "The project where all the resources will be created."
}
variable "region" {
  default = "us-central1"
  description = "The region where all resources will be created."
}
variable "zone" {
  default = "us-central1-b"
  description = "The zone where all resources will be created."
}
variable "backend_cluster_name" {
  default = "backend-cluster"
  description = "The name of the backend Dataproc cluster configured with Hive and the Ranger plugin."
}
variable "proxy_cluster_name" {
  default = "proxy-cluster"
  description = "The name of the proxy Dataproc cluster configured with Knox"
}
// Please change these default passwords for any non-trivial use of the solution
variable "mysql_root_password" {
  default = "mysql-root-password-99"
  description = "The password of the MySQL instance root user where the Ranger policies database will be created."
}
variable "ranger_admin_password" {
  default = "ranger-admin-password-99"
  description = "The password for the Ranger UI admin user"
}
variable "ranger_db_admin_password" {
  default = "ranger-db-admin-password-99"
  description = "The password of the Ranger policies database admin user"
}
variable "cluster_service_account" {
  default = "cluster-service-account"
  description = "The service account for the cluster to be authenticated as, when running jobs and accessing Google Cloud resources."
}