# Hybrid Cloud Deployment

Dit project zet een hybrid cloud omgeving op waarin een Azure VM en een ESXi VM
samenwerken. De VM's worden aangemaakt met Terraform, ingericht met Cloud-Init en
Ansible, en draaien een applicatie in Docker via Docker Compose. GitHub Actions
controleert bij elke push automatisch of de code klopt.

## Hoe het werkt

Er zijn twee omgevingen:

1. Een ESXi VM (databaseserver) die lokaal in het labnetwerk draait.
2. Een Azure VM die in de cloud draait.

Beide VM's worden met Terraform aangemaakt. Cloud-Init zorgt voor de basis (user,
docker install) en daarna neemt Ansible het over om Docker en de applicatie te
installeren. De app is een nginx container die via Docker Compose draait en een
simpele webpagina serveert.

De verbinding tussen de twee omgevingen loopt via SSH. Bij het aanmaken van de
ESXi VM wordt de private key van Azure meegegeven (via Cloud-Init). Daardoor kan
de ESXi VM straks naar de Azure VM SSH'en zonder wachtwoord. Dat is de hybrid
connectie.

## Mapstructuur

| Map | Wat er in zit |
|-----|--------|
| `terraform/azure/` | Terraform code voor de Azure VM, netwerk, NSG en public IP |
| `terraform/esxi/`  | Terraform code voor de ESXi VM via de `josenk/esxi` provider |
| `ansible/roles/docker/`    | Zelfgemaakte role die docker.io en de compose plugin installeert |
| `ansible/roles/container/` | Zelfgemaakte role die de compose app uitrolt (heeft docker role nodig) |
| `ansible/hybrid_test.yml`  | Playbook dat test of de ESXi VM de Azure VM kan bereiken |
| `.github/workflows/deploy.yml` | GitHub Actions pipeline die de code valideert |

## Over de GitHub Actions pipeline

De pipeline draait bij elke push en doet het volgende:

- controleert of de Terraform code netjes geformatteerd is (`terraform fmt`)
- valideert de Terraform code voor zowel Azure als ESXi (`terraform validate`)
- checkt of de Ansible playbooks geldig zijn (`--syntax-check`)

De pipeline doet dus de validatie en tests, niet de echte deployment. Dat is een
bewuste keuze. Terraform houdt bij welke VM's er al draaien in een state bestand,
en dat bestand staat in `.gitignore` zodat het niet in Git komt. De GitHub runner
heeft die state dus niet en zou een tweede VM proberen aan te maken. Daarom draai
ik de echte deployment gecontroleerd vanaf mijn eigen machine met `terraform apply`,
en gebruik ik de pipeline om de code automatisch te testen. Zo blijft alles
overzichtelijk en voorkom ik dubbele of kapotte deployments.

## Zelf draaien (WSL)

```bash
# 1. SSH keys aanmaken
ssh-keygen -t ed25519 -f ~/.ssh/azure  -C azure-vm -N ""
ssh-keygen -t ed25519 -f ~/.ssh/skylab -C esxi-vm  -N ""

# 2. Tools installeren
sudo apt install -y ansible
ansible-galaxy collection install -r ansible/requirements.yml

# 3. Secrets lokaal zetten (staan in .gitignore, komen niet in Git)
cp terraform/esxi/secret.auto.tfvars.example terraform/esxi/secret.auto.tfvars
# vul hierin het esxi_password in

# 4. ESXi VM deployen (ovftool moet geinstalleerd zijn en SSH aan op de ESXi host)
cd terraform/esxi
terraform init
terraform apply
```

Na `terraform apply` maakt Terraform de VM aan, draait Cloud-Init en voert Ansible
de rest uit. Daarna kun je met je key inloggen zonder wachtwoord:

```bash
ssh -i ~/.ssh/skylab test_user@<ip-van-de-vm>
```

En de app bekijken:

```bash
curl http://<ip-van-de-vm>
```

## Secrets

Wachtwoorden en de subscription ID staan nooit in de code. Ze worden op twee
plekken bijgehouden:

- Lokaal in `secret.auto.tfvars` bestanden (staan in `.gitignore`)
- In GitHub onder Settings > Secrets voor de pipeline

De `.example` bestanden laten zien welke variabelen je moet invullen, zonder de
echte waardes.

## Best practices die ik heb toegepast

- Geen secrets in Git, alles via secret bestanden en GitHub Secrets
- `.gitignore` sluit state, keys en secret bestanden uit
- Eigen Ansible roles met Galaxy structuur (`meta/main.yml` en een dependency
  tussen de roles)
- Code wordt automatisch getest in de pipeline voordat er iets mee gebeurt
- Docker geinstalleerd vanuit docker.io, app draait via Docker Compose

## Over de Azure omgeving

Voor deze opdracht heb ik een gratis Azure proefaccount gebruikt. Daardoor liep ik
tegen een paar beperkingen aan die je terugziet in de code:

- De regio staat op `germanywestcentral`. De standaard regio's westeurope en
  northeurope hadden geen capaciteit voor nieuwe gratis accounts.
- De VM size is `Standard_B1s`, een kleine VM, om binnen het gratis tegoed te
  blijven.
- Bij een verse subscription moesten de resource providers (Microsoft.Network,
  Microsoft.Compute en Microsoft.Storage) eenmalig geregistreerd worden voordat
  Terraform resources kon aanmaken.

De regio en VM size worden via `terraform.tfvars` ingesteld, zodat je de code niet
hoeft aan te passen als je een andere regio wilt gebruiken.

## Status

Beide omgevingen werken volledig. De ESXi VM en de Azure VM worden aangemaakt met
Terraform, ingericht met Cloud-Init en Ansible, en draaien de app via Docker
Compose. Passwordless SSH werkt, en de hybrid connectie is getest: de ESXi VM logt
met de geinjecteerde Azure key in op de Azure VM en haalt daar de applicatie op.