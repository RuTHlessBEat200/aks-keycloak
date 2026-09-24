# aks-keycloak

Terraform erstellt einen AKS-Cluster auf Azure und deployt darauf via Helm:
CloudNativePG (Postgres-Operator + Cluster) und Keycloak.

## Voraussetzung: ejson

Secrets (Azure-Credentials, Keycloak-Admin-Passwort) werden mit
[ejson](https://github.com/Shopify/ejson) verschlüsselt in
`ejson/secrets.ejson` abgelegt. `ejson` und `jq` müssen lokal installiert
sein.

### Schlüsselpaar erzeugen

```sh
ejson keygen
```

Das gibt einen Public und einen Private Key aus. Der Private Key muss lokal
unter `/opt/ejson/keys/<public-key>` liegen (Standardpfad von ejson):

```sh
sudo mkdir -p /opt/ejson/keys
sudo sh -c 'echo "<PRIVATE_KEY>" > /opt/ejson/keys/<PUBLIC_KEY>'
sudo chmod 600 /opt/ejson/keys/<PUBLIC_KEY>
```

Der Private Key wird niemals ins Git-Repo committet.

### Secrets eintragen

`ejson/secrets.ejson` mit dem eigenen Public Key anlegen:

```json
{
  "_public_key": "<PUBLIC_KEY>",
  "azure": {
    "client_id": "REPLACE_ME",
    "client_secret": "REPLACE_ME",
    "tenant_id": "REPLACE_ME",
    "subscription_id": "REPLACE_ME"
  },
  "keycloak": {
    "admin_password": "REPLACE_ME"
  }
}
```

`azure.*` sind die Credentials eines Azure Service Principals mit Rechten
zum Anlegen von Resource Group und AKS-Cluster. `keycloak.admin_password`
ist das gewünschte Admin-Passwort für die Keycloak-Konsole.

Danach verschlüsseln:

```sh
ejson encrypt ejson/secrets.ejson
```

Zum späteren Prüfen/Ändern der Werte:

```sh
ejson decrypt ejson/secrets.ejson   # zeigt Klartext an
# Werte im Klartext-Output anpassen, dann wieder:
ejson encrypt ejson/secrets.ejson
```

Terraform ruft `ejson decrypt` beim Plan/Apply automatisch über
`terraform/scripts/decrypt-secrets.sh` und
`terraform/scripts/decrypt-keycloak-secrets.sh` auf.

## Deployment

```sh
cd terraform
terraform init
terraform apply
```

Der Apply dauert einige Minuten (AKS-Cluster-Erstellung, LoadBalancer-IP,
Zertifikatsausstellung). Am Ende zeigt `terraform output keycloak_url` die
öffentliche URL der Keycloak-Konsole.
