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

// Google Provider is inherited from root module

// Create bucket for the initialization action
resource "google_storage_bucket" "knox_bucket" {
  name          = "${var.project_id}-knox"
  location      = var.region
  force_destroy = true

  provisioner "local-exec" {
    // heredoc-style multiline command
    command = <<EOT
      export PROJECT_ID=${var.project_id} 
      export ZONE=${var.zone}
      export BACKEND_CLUSTER_NAME=${var.backend_cluster_name}
      ${path.module}/scripts/configure-knox-init-action.sh
    EOT
  }

  provisioner "local-exec" {
    command = "gsutil cp ${path.module}/scripts/add-sample-ldap-user.sh gs://${google_storage_bucket.knox_bucket.name}"
  }
}

// Create proxy cluster with Apache Knox
resource "google_dataproc_cluster" "proxy_cluster" {
  name   = var.proxy_cluster_name
  region = var.region

  cluster_config {

    gce_cluster_config {
      zone            = var.zone
      service_account = var.google_service_account-cluster_service_account.email
      metadata        = { 
        "knox-gw-config" = "gs://${google_storage_bucket.knox_bucket.name}" 
      }
    }

    initialization_action {
      script = "gs://goog-dataproc-initialization-actions-${var.region}/knox/knox.sh"
   }

    initialization_action {
      script = "gs://${google_storage_bucket.knox_bucket.name}/add-sample-ldap-user.sh"
   }
  }

  depends_on = [var.google_project_service-apis, var.google_project_iam_binding-cluster_service_account]
}