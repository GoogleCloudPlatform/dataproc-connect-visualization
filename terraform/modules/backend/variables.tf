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
}
variable "region" {
}
variable "zone" {
}
variable "backend_cluster_name" {
}
variable "proxy_cluster_name" {
}
variable "mysql_root_password" {
}
variable "ranger_admin_password" {
}
variable "ranger_db_admin_password" {
}
variable "cluster_service_account" {
}

// Internal variables to pass module dependencies
variable google_project_service-apis {
  type    = any   // Declared as type `any` because no need to access any of its attributes
  default = null
  description = "Terraform resource: enables project-level APIs and services"
}

variable google_service_account-cluster_service_account {
  type = object({
    email = string
  })
  default = null
  description = "Terraform resource: service account for the clusters to be authenticated as."
}

variable google_project_iam_binding-cluster_service_account {
  type    = any
  default = null 
  description = "Terraform resource: binds necessary roles to the cluster service account."
}

variable google_dataproc_cluster-proxy_cluster {
  type    = any
  default = null 
  description = "Terraform resource: proxy cluster running LDAP server. Backend cluster syncs user IDs from it."
}