resource "google_compute_network" "myvpc" {
  name                    = "${var.spry_tree_project}-vpc"
  auto_create_subnetworks = "true"
}