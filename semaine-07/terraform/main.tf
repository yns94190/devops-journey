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
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = var.subnet_cidr
  display_name      = "devops-journey-subnet"
  dns_label         = "devopssub"
  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
}

# Semaine 08 : sortie Internet pour le VCN (nécessaire pour qu'une future
# instance dans ce subnet puisse être jointe depuis l'extérieur, comme le
# VPS de semaine-05 qui lui a été créé manuellement hors de ce VCN).
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "devops-journey-igw"
  enabled        = true
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "devops-journey-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "devops-journey-sl"

  # SSH (comme sur le VPS de semaine-05)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (comme sur le VPS de semaine-05)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
