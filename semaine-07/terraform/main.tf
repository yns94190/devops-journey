# Première ressource provisionnée via Terraform : un réseau (VCN + subnet)
# plutôt qu'une instance compute, pour ne pas risquer de dépasser le quota
# Always Free (le VPS de semaine-05 existe déjà, créé manuellement).

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "devops-journey-vcn"
  dns_label      = "devopsvcn"
}

resource "oci_core_subnet" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = var.subnet_cidr
  display_name   = "devops-journey-subnet"
  dns_label      = "devopssub"
}
