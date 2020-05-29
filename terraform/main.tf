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

// Configure the Google Cloud provider
provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

// Enable the Cloud APIs for Dataproc, Cloud SQL, and Cloud Key Management Service (KMS)
resource "google_project_service" "apis" {
  for_each = toset([
    "dataproc.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com"
  ])

  service            = each.key
  project            = var.project_id
  disable_on_destroy = false
}

// Create service account for the clusters to be authenticated as
// https://cloud.google.com/sdk/gcloud/reference/beta/dataproc/clusters/create#--service-account
 resource "google_service_account" "cluster_service_account" {
  account_id   = var.cluster_service_account
  display_name = "Dataproc Cluster Service Account"

  depends_on = [google_project_service.apis]
 }

// Set roles for cluster service account
resource "google_project_iam_binding" "cluster_service_account" {
  for_each = toset([
    "dataproc.worker",
    "cloudsql.editor",
    "cloudkms.cryptoKeyDecrypter"
  ])

  role    = "roles/${each.key}"
  members = [
    "serviceAccount:${google_service_account.cluster_service_account.email}"
  ]
}

// Backend cluster with Ranger and Hive
module "backend" {
  source = "./modules/backend"

  project_id               = var.project_id 
  region                   = var.region 
  zone                     = var.zone 
  backend_cluster_name     = var.backend_cluster_name 
  proxy_cluster_name       = var.proxy_cluster_name 
  mysql_root_password      = var.mysql_root_password 
  ranger_admin_password    = var.ranger_admin_password 
  ranger_db_admin_password = var.ranger_db_admin_password 
  cluster_service_account  = var.cluster_service_account

  google_project_service-apis = google_project_service.apis
  google_service_account-cluster_service_account = google_service_account.cluster_service_account
  google_project_iam_binding-cluster_service_account = google_project_iam_binding.cluster_service_account

  google_dataproc_cluster-proxy_cluster = module.proxy.google_dataproc_cluster-proxy_cluster

}

// Proxy cluster with Knox
module "proxy" {
  source = "./modules/proxy"

  project_id               = var.project_id 
  region                   = var.region 
  zone                     = var.zone 
  backend_cluster_name     = var.backend_cluster_name 
  proxy_cluster_name       = var.proxy_cluster_name 

  google_project_service-apis = google_project_service.apis
  google_service_account-cluster_service_account = google_service_account.cluster_service_account
  google_project_iam_binding-cluster_service_account = google_project_iam_binding.cluster_service_account
}