variable "tenancy_ocid" {
  description = "OCID du tenancy OCI"
  type        = string
}

variable "user_ocid" {
  description = "OCID de l'utilisateur OCI (compte utilisé pour l'authentification API)"
  type        = string
}

variable "fingerprint" {
  description = "Empreinte de la clé API affichée par la console OCI après ajout de la clé publique"
  type        = string
}

variable "private_key_path" {
  description = "Chemin local vers la clé privée API (jamais versionné)"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "Région OCI (ex: eu-paris-1)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID du compartiment cible (racine = tenancy_ocid si aucun sous-compartiment)"
  type        = string
}

variable "vcn_cidr" {
  description = "Bloc CIDR du VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Bloc CIDR du subnet"
  type        = string
  default     = "10.0.1.0/24"
}
