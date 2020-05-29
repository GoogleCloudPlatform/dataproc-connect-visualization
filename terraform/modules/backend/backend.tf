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

// ------------
// Ranger database
// ------------

// Create the Ranger database instance
resource "google_sql_database_instance" "ranger_db" {
  name   = "cloudsql-mysql"
  region = var.region
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-n1-standard-1"
  }
  depends_on = [var.google_project_service-apis]
}

// Change the DB root password
resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.ranger_db.name
  host     = "%"
  password = var.mysql_root_password
}

// ------------
// Password Encryption
// ------------

// Create the KMS Keyring 
resource "google_kms_key_ring" "keyring" {
  name     = "my-keyring"
  location = "global"

  depends_on = [var.google_project_service-apis]
}

// Create key to encrypt passwords
resource "google_kms_crypto_key" "key" {
  name     = "my-key"
  key_ring = google_kms_key_ring.keyring.self_link
  purpose  = "ENCRYPT_DECRYPT"

}

// Create bucket to store encrypted files
resource "google_storage_bucket" "ranger_bucket" {
  name          = "${var.project_id}-ranger"
  location      = var.region
  force_destroy = true

  depends_on = [google_kms_crypto_key.key]

  provisioner "local-exec" {
    // heredoc-style multiline command
    command = <<EOT
      export PROJECT_ID=${var.project_id} 
      export MYSQL_ROOT_PASSWORD=${var.mysql_root_password} 
      export RANGER_ADMIN_PASSWORD=${var.ranger_admin_password} 
      export RANGER_DB_ADMIN_PASSWORD=${var.ranger_db_admin_password} 
      ${path.module}/scripts/encrypt-and-cp-passwords.sh
    EOT
  }
}

// ------------
// Backend cluster
// ------------

// Create Solr bucket to store Ranger audit logs
resource "google_storage_bucket" "solr_bucket" {
  name          = "${var.project_id}-solr"
  location      = var.region
  force_destroy = true
}

// Create Hive bucket to store Hive data
resource "google_storage_bucket" "hive_bucket" {
  name          = "${var.project_id}-hive"
  location      = var.region
  force_destroy = true

  provisioner "local-exec" {
    // Copy cluster init action script to load data into Hive
    command = "gsutil cp ${path.module}/scripts/load-data-into-hive.sh gs://${google_storage_bucket.hive_bucket.name}"
  }
}

// Configure the Google Cloud BETA provider
// Component gateway, SOLR and RANGER are available as BETA in version >= 3.22
provider "google-beta" {
 project     = var.project_id
 region      = var.region
 zone        = var.zone
 version     = ">= 3.22"
}

// Create Backend Cluster
resource "google_dataproc_cluster" "backend_cluster" {
  provider = google-beta
  name     = var.backend_cluster_name
  region   = var.region

  cluster_config {

    // Zone, service account and scopes
    gce_cluster_config {
      zone = var.zone
      service_account = var.google_service_account-cluster_service_account.email
      service_account_scopes = [
        "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
        "https://www.googleapis.com/auth/cloudkms",
        "https://www.googleapis.com/auth/devstorage.read_write",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/sqlservice.admin"
        ]
    }

    // Enable Component Gateway
    endpoint_config {
      enable_http_port_access = "true"
    }

    software_config {

      // RANGER: authorization, SOLR: audit search
      optional_components = ["SOLR", "RANGER"]

      override_properties = {
        // Encryption key
        "dataproc:ranger.kms.key.uri"="projects/${var.project_id}/locations/global/keyRings/my-keyring/cryptoKeys/my-key"
        
        // Ranger admin password
        "dataproc:ranger.admin.password.uri"="gs://${var.project_id}-ranger/ranger-admin-password.encrypted"
        
        // Ranger DB
        "dataproc:ranger.db.admin.password.uri"="gs://${var.project_id}-ranger/ranger-db-admin-password.encrypted"
        "dataproc:ranger.cloud-sql.instance.connection.name"="${var.project_id}:${var.region}:${google_sql_database_instance.ranger_db.name}"
        "dataproc:ranger.cloud-sql.root.password.uri"="gs://${var.project_id}-ranger/mysql-root-password.encrypted"

        // Ranger audit logs
        "dataproc:solr.gcs.path"="gs://${var.project_id}-solr"

        // Hive HTTP
        "hive:hive.server2.thrift.http.port"="10000"
        "hive:hive.server2.thrift.http.path"="cliservice"
        "hive:hive.server2.transport.mode"="http"
      }
    }

    initialization_action {
      script      = "gs://${google_storage_bucket.hive_bucket.name}/load-data-into-hive.sh"
    }

  }

  provisioner "local-exec" {
    // heredoc-style multiline command
    command = <<EOT
      export PROJECT_ID=${var.project_id} 
      export ZONE=${var.zone}
      export BACKEND_CLUSTER_NAME=${var.backend_cluster_name}
      export PROXY_CLUSTER_NAME=${var.proxy_cluster_name}
      export MODULE_PATH=${path.module}
      ${path.module}/scripts/configure-ranger-usersync-ldap.sh
    EOT
  }
  
  depends_on = [google_sql_user.root, var.google_project_iam_binding-cluster_service_account, google_storage_bucket.hive_bucket, var.google_dataproc_cluster-proxy_cluster]
}
