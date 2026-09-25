# Semaine 08 — Cloud (OCI, suite Terraform)

## 1. Objectifs
- Ajouter Internet Gateway + route table + security list au VCN Terraform de semaine-07, pour que ce VCN soit réellement utilisable par une instance
- Importer le VPS existant (`devops-server`, semaine-05, créé manuellement dans la console OCI) dans le state Terraform

On reste sur Oracle Cloud (Free Tier) — pas de changement de provider. Le code Terraform continue de vivre dans `semaine-07/terraform/` (même state, même VCN) : semaine-08 en est la suite logique plutôt qu'un nouveau stack séparé.

## 2. Réseau : IGW + route table + security list

Ajoutés dans `semaine-07/terraform/main.tf` :
- `oci_core_internet_gateway.main` — sortie/entrée Internet pour le VCN
- `oci_core_route_table.main` — une règle `0.0.0.0/0 → IGW`
- `oci_core_security_list.main` — ingress TCP 22 (SSH) et 80 (HTTP) depuis `0.0.0.0/0`, egress all
- `oci_core_subnet.main` mis à jour pour référencer cette route table et cette security list (au lieu des ressources par défaut créées implicitement avec le VCN)

```
terraform plan   # Plan: 3 to add, 1 to change, 0 to destroy
terraform apply -auto-approve
# Apply complete! Resources: 3 added, 1 changed, 0 destroyed.
```

Outputs ajoutés dans `outputs.tf` : `internet_gateway_id`, `route_table_id`, `security_list_id`.

## 3. Import du VPS `devops-server`

### Erreur rencontrée : mauvaise instance au premier essai
Le compte OCI héberge **deux** instances : `jobhunter` (projet perso séparé) et `devops-server` (le VPS de semaine-05). Une première recherche via `data "oci_core_instances"` filtrée uniquement sur `var.compartment_ocid` n'a remonté que `jobhunter` (l'instance la plus visible/seule listée dans un premier test partiel) — son IP publique (`141.253.98.8`) ne correspondait pas à celle de `.vps-local.md` (`141.253.108.240`). Élargir la recherche à toutes les instances du compartiment a bien remonté les deux ; `devops-server` a été identifié par correspondance exacte de l'IP publique.

**Leçon :** avant un `terraform import` sur une infra qui n'a pas été entièrement créée par l'agent, toujours vérifier l'identité de la ressource (IP, tags, date de création) plutôt que de supposer qu'une seule instance trouvée est la bonne.

### Démarche
1. Data sources temporaires (`discover.tf`, supprimé après usage) pour retrouver, sans OCI CLI (non installée), les attributs réels de l'instance : `oci_core_instance`, `oci_core_vnic_attachments` + `oci_core_vnic`, `oci_core_boot_volume_attachments`
2. Écriture d'un bloc `resource "oci_core_instance" "devops_server"` (`semaine-07/terraform/instance.tf`) reproduisant fidèlement compartment, availability domain, shape (`VM.Standard.A1.Flex`, 1 OCPU / 6 Go), image, clé SSH — avec `lifecycle.ignore_changes` sur `boot_volume_size_in_gbs` et `defined_tags` (attributs gérés/calculés côté OCI, pas par ce bloc)
3. `terraform import oci_core_instance.devops_server <OCID>`
4. `terraform plan` après import : **aucun changement** sur la ressource réelle (seuls les outputs de debug temporaires disparaissent) → le bloc écrit correspond exactement à l'état réel, aucun risque de recréation/modification involontaire au prochain `apply`

```
terraform import oci_core_instance.devops_server ocid1.instance.oc1.eu-paris-1.anrwiljr37ygc7ac6z55voqa54k5dwed3xtym674f245rprpxwxw4aqvnzna
# Import successful!

terraform plan
# (après suppression de discover.tf) aucune ressource réelle à modifier
```

Le VPS vit dans un subnet distinct de celui géré par ce projet Terraform (créé manuellement lors du provisioning initial semaine-05) — l'import ne modifie pas sa configuration réseau, il ajoute seulement la ressource au state.

### État final du state
```
terraform state list
oci_core_instance.devops_server
oci_core_internet_gateway.main
oci_core_route_table.main
oci_core_security_list.main
oci_core_subnet.main
oci_core_vcn.main
```

## Points clés
- `terraform apply` réel (ressources cloud) déclenche systématiquement une demande de confirmation explicite côté outil, même en mode autonome — normal pour ce type d'action, pas un blocage à contourner
- Sans OCI CLI installée, les `data` sources Terraform (avec le provider déjà authentifié) suffisent pour explorer/découvrir des ressources existantes avant un import
- Toujours valider un import (`terraform plan` post-import) avant de considérer la ressource comme correctement gérée — un bloc `resource` incomplet ou incorrect pourrait provoquer une recréation destructive au prochain `apply`

## Reste à faire
- Étendre `security_list` si besoin (autres ports) et envisager des NSG par service plutôt qu'une security list globale
- Explorer un backend distant pour le state Terraform (reporté depuis semaine-07)
- Planifier la suite de semaine-08 / semaines 09-12 (Kubernetes ? monitoring/observabilité ? secrets management ?)
