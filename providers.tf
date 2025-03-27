variable "project_id" {
  description = "spry-tree-453513-c0"
}

variable "region" {
  description = "europe-west4"
}

variable "zone" {
  description = "europe-west4-a"
}

variable "service_account_email" {
  description = "The email of the service account to be used for authentication"
  type        = string
  default     = "479065467795-compute@developer.gserviceaccount.com"
}



terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }
}


provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file("downloaded.json")
}

resource "google_container_cluster" "my_cluster" {
  name     = "my-cluster"
  location = var.zone

  node_pool {
    name       = "default-node-pool"
    node_count = 3

    node_config {
      machine_type = "n2-standard-2"
    }
  }
}


# # Configure kubernetes provider with Oauth2 access token.
# # https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# # This fetches a new token, which will expire in 1 hour.
# data "google_client_config" "default" {}

# provider "kubernetes" {
#   host                   = "https://${google_container_cluster.my_cluster.endpoint}"
#   token                  = data.google_client_config.default.access_token
#   cluster_ca_certificate = base64decode(google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
# }



