# Semaine 08 : import du VPS de semaine-05 (créé manuellement dans la
# console OCI) dans le state Terraform. Ce VPS vit dans un VCN/subnet
# distinct de celui géré par ce projet (oci_core_vcn.main) — l'import ne
# change rien à sa configuration réseau réelle, il ajoute juste la
# ressource au state pour pouvoir la gérer via Terraform à l'avenir.

resource "oci_core_instance" "devops_server" {
  compartment_id      = var.compartment_ocid
  availability_domain = "OpDY:EU-PARIS-1-AD-1"
  display_name        = "devops-server"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1.eu-paris-1.aaaaaaaalnp6swykhh6ckjhwhr4ejxr53oc5crzcgmpos37jthj623xg5yba"
  }

  metadata = {
    ssh_authorized_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5s6OHkqJVlWREPWj9hgA4MjhnoWY0y2nMGXA54Q5os yaniswalim@gmail.com"
  }

  # Champs gérés hors Terraform à l'origine (création manuelle) : on évite
  # que Terraform ne tente de les "corriger" lors d'un futur apply.
  lifecycle {
    ignore_changes = [
      source_details[0].boot_volume_size_in_gbs,
      defined_tags,
    ]
  }
}
