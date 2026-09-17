# Semaine 07 — Terraform

## Objectif
Passer du provisioning manuel (semaine-05, VPS créé via la console OCI) à l'Infrastructure as Code avec Terraform, en provisionnant une première ressource réseau sur Oracle Cloud.

## 1. Installation Terraform
Installation **sans sudo** (contrairement à Ansible en semaine-06, qui nécessitait un `apt install` interactif) : binaire téléchargé directement dans `~/.local/bin`, déjà présent dans le `PATH`.
```bash
curl -sO https://releases.hashicorp.com/terraform/1.16.3/terraform_1.16.3_linux_amd64.zip
unzip -o -q terraform_1.16.3_linux_amd64.zip -d ~/.local/bin
chmod +x ~/.local/bin/terraform
terraform version   # Terraform v1.16.3
```

## 2. Structure
```
semaine-07/terraform/
├── versions.tf               # contrainte Terraform >= 1.16, provider oracle/oci ~> 6.0
├── provider.tf                # bloc provider "oci" (auth API Key)
├── variables.tf                # tenancy_ocid, user_ocid, fingerprint, region, compartment_ocid, cidrs
├── main.tf                    # ressources : oci_core_vcn + oci_core_subnet
├── outputs.tf                  # vcn_id, subnet_id
├── terraform.tfvars.example    # tracké, placeholders
├── terraform.tfvars            # gitignored — vraies valeurs
└── .terraform.lock.hcl         # tracké — verrouille la version exacte du provider
```

## 3. Authentification OCI (API Key)
Le VPS de semaine-05 avait été créé à la main dans la console, donc aucun credential API n'existait. Génération locale d'une paire de clés (jamais transportée, jamais dans le repo) :
```bash
mkdir -p ~/.oci && chmod 700 ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 600 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```
Étapes manuelles obligatoires côté utilisateur (console OCI, non automatisables) :
1. Profil OCI → *My profile* → *API keys* → *Add API Key* → coller la clé publique
2. La console génère la **fingerprint** affichée dans la liste des clés
3. Récupération de `tenancy_ocid`, `user_ocid`, `region` sur les pages profil/tenancy

`terraform.tfvars` (gitignored) rempli avec ces 5 valeurs (`compartment_ocid` = `tenancy_ocid`, pas de sous-compartiment créé pour l'instant).

## 4. Ressources provisionnées : VCN + subnet
Choix volontaire : un réseau plutôt qu'une instance compute, pour ne pas risquer de dépasser le quota **Always Free** (le VPS de semaine-05 existe déjà et compte dans ce quota).

```hcl
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]      # 10.0.0.0/16
  display_name   = "devops-journey-vcn"
  dns_label      = "devopsvcn"
}

resource "oci_core_subnet" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = var.subnet_cidr     # 10.0.1.0/24
  display_name   = "devops-journey-subnet"
  dns_label      = "devopssub"
}
```

## 5. Commandes utilisées
```bash
cd semaine-07/terraform
terraform init      # télécharge le provider oracle/oci, crée .terraform.lock.hcl
terraform plan       # prévisualise les changements
terraform apply -auto-approve
```

## 6. Résultats obtenus
`terraform init` : provider `oracle/oci` v6.37.0 installé et verrouillé.

`terraform plan` : `Plan: 2 to add, 0 to change, 0 to destroy` (VCN + subnet).

`terraform apply` :
```
oci_core_vcn.main: Creation complete after 1s [id=ocid1.vcn.oc1.eu-paris-1.amaaaaaa37ygc7aac...]
oci_core_subnet.main: Creation complete after 3s [id=ocid1.subnet.oc1.eu-paris-1.aaaaaaaav436avjt6...]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
subnet_id = "ocid1.subnet.oc1.eu-paris-1...."
vcn_id    = "ocid1.vcn.oc1.eu-paris-1...."
```

## 7. Le fichier `terraform.tfstate`
Après `terraform apply`, Terraform a créé `terraform.tfstate` dans `semaine-07/terraform/` (backend local par défaut, pas de backend distant configuré).

**Ce que c'est :** un fichier JSON qui fait correspondre chaque ressource déclarée dans le code (`oci_core_vcn.main`, `oci_core_subnet.main`) à son état réel sur OCI (ID, tous les attributs renvoyés par l'API — y compris ceux calculés comme `route_table_id`, `default_security_list_id`, etc.). C'est la seule source de vérité que Terraform utilise pour savoir ce qui existe déjà et calculer le diff lors du prochain `plan`/`apply`. Sans lui, Terraform ne peut pas savoir qu'une ressource lui appartient déjà et tenterait de la recréer.

**Pourquoi gitignored (`semaine-07/terraform/*.tfstate*`) :**
- Il contient les OCID réels des ressources et potentiellement des attributs sensibles (selon les ressources gérées, il peut inclure des secrets en clair — mots de passe, clés) — jamais adapté à un repo public
- C'est un état mutable et local : deux personnes (ou l'agent et l'utilisateur) qui appliquent depuis des copies différentes du state divergent et peuvent corrompre l'infra réelle — un state ne se fusionne pas comme du code
- En solo sur ce projet, le state local suffit ; en équipe, il faudrait un backend distant partagé (OCI Object Storage, Terraform Cloud...) avec verrouillage, pas un fichier versionné dans Git

## 8. Détruire l'infrastructure : `terraform destroy`
```bash
cd semaine-07/terraform
terraform destroy
```
**⚠️ Avertissement :** cette commande supprime **réellement et immédiatement** toutes les ressources gérées par ce state (ici le VCN et le subnet) sur le tenancy OCI — action irréversible, à ne lancer que pour décommissionner volontairement l'infra de cette semaine. Comme pour `apply`, `destroy` affiche d'abord un plan (`- destroy`) et demande une confirmation manuelle (`yes`) avant d'agir ; ne jamais l'enchaîner avec `-auto-approve` sauf certitude absolue. Pas exécuté à ce stade — le VCN et le subnet restent en place.

## Erreurs rencontrées
- **`~/.oci/config` absent :** le VPS de semaine-05 avait été créé entièrement via la console OCI, donc aucune credential API n'existait en local. Résolu en générant une paire de clés API localement (`openssl genrsa`) et en demandant à l'utilisateur de coller la clé publique dans la console (étape manuelle irréductible, pas automatisable par l'agent).
- **`sudo` interactif indisponible pour l'agent :** comme pour Ansible en semaine-06, aucune installation nécessitant un mot de passe `sudo` ne peut être lancée par l'agent. Contournement pour Terraform : installation du binaire directement dans `~/.local/bin` (déjà dans le `PATH`), sans passer par un paquet système — aucun `sudo` requis pour Terraform lui-même.
- **Erreur de quoting PowerShell → WSL → bash :** une commande `curl | grep -o "..."` avec guillemets imbriqués a échoué (`Le terminateur ' est manquant dans la chaîne`) à cause du passage de la commande à travers trois couches de shell (PowerShell, `wsl -e bash -lc`, bash). Corrigé en utilisant une chaîne PowerShell à guillemets simples (pas d'interpolation) pour l'appel externe, laissant les guillemets internes intacts pour bash.

## Points clés
- Terraform en binaire local évite le blocage `sudo` interactif rencontré avec Ansible (semaine-06) — pas de mot de passe à fournir
- L'authentification OCI par API Key nécessite une étape manuelle irréductible dans la console (ajout de la clé publique) — Terraform (ni l'agent) ne peut la remplacer
- `.terraform.lock.hcl` est **tracké** (contrairement à `.terraform/` et `terraform.tfvars`) pour garantir la reproductibilité de la version du provider entre environnements
- Ressource réseau choisie plutôt qu'une instance compute pour ne pas consommer de quota Always Free supplémentaire

## Reste à faire
- Importer le VPS existant (semaine-05) dans le state Terraform (`terraform import`) pour unifier IaC et infra manuelle
- Ajouter Internet Gateway + route table + security list pour rendre ce VCN réellement utilisable par une instance
- Explorer un backend distant (OCI Object Storage) pour le state Terraform plutôt qu'un fichier local
