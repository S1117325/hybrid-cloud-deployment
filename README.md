# Hybrid Cloud Deployment

Volledig geautomatiseerde hybrid cloud deployment die **Azure VM's** en **ESXi VM's**
combineert. De hele keten (provisioning + configuratie + applicatie) draait via
**GitHub Actions**, met **Terraform**, **Cloud-Init**, **Ansible** en **Docker Compose**.

## Architectuur

```
GitHub Actions (self-hosted runner in labnetwerk)
│
├── Terraform (Azure)  ── Cloud-Init ─┐
│      └── Azure Linux VM             │
│            └── Ansible ── Docker Compose ── nginx "Hello World" app  :80
│
├── Terraform (ESXi)   ── Cloud-Init ─┤
│      └── ESXi guest VM              │  (Azure private key geïnjecteerd)
│            └── Ansible ── Docker
│
└── Hybrid test: ESXi-VM SSH't met de Azure-key naar de Azure-VM
```

De **hybrid connectie** wordt bewezen doordat de ESXi-VM met de (via Cloud-Init
geïnjecteerde) Azure private key naar de Azure-VM SSH't en daar de draaiende
applicatie ophaalt.

## Structuur

| Pad | Inhoud |
|-----|--------|
| `terraform/azure/` | Azure VM, netwerk, NSG, public IP, cloud-init |
| `terraform/esxi/`  | ESXi guest VM via `josenk/esxi` provider |
| `ansible/roles/docker/`    | Eigen Galaxy-role: installeert docker.io + compose plugin |
| `ansible/roles/container/` | Eigen Galaxy-role: rolt de compose-app uit (dependency op `docker`) |
| `ansible/hybrid_test.yml`  | Test die de hybrid verbinding verifieert |
| `.github/workflows/deploy.yml` | Volledige CI/CD pipeline |

## Benodigde secrets (GitHub → Settings → Secrets → Actions)

| Secret | Uitleg |
|--------|--------|
| `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` / `ARM_TENANT_ID` / `ARM_SUBSCRIPTION_ID` | Azure Service Principal |
| `ESXI_PASSWORD` | Wachtwoord ESXi-host |
| `SSH_AZURE_PRIVATE` / `SSH_AZURE_PUBLIC` | Azure keypair |
| `SSH_SKYLAB_PRIVATE` / `SSH_SKYLAB_PUBLIC` | ESXi keypair |

## Lokaal draaien (WSL)

```bash
# 1. SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/azure  -C azure-vm -N ""
ssh-keygen -t ed25519 -f ~/.ssh/skylab -C esxi-vm  -N ""

# 2. Tools
sudo apt install -y ansible
ansible-galaxy collection install -r ansible/requirements.yml
az login

# 3. Secrets lokaal zetten (worden door .gitignore genegeerd)
cp terraform/azure/secret.auto.tfvars.example terraform/azure/secret.auto.tfvars
cp terraform/esxi/secret.auto.tfvars.example  terraform/esxi/secret.auto.tfvars
# -> vul je subscription_id en esxi_password in

# 4. Azure
cd terraform/azure && terraform init && terraform apply

# 5. ESXi (vereist ovftool + SSH aan op de ESXi-host)
cd ../esxi && terraform init && terraform apply
```

## Best practices in dit project

- Secrets niet in Git: subscription ID en ESXi-wachtwoord via secrets / `TF_VAR_*` / `secret.auto.tfvars`.
- `.gitignore` sluit state, keys en `*secret*` / `*.auto.tfvars` uit.
- Eigen Ansible-roles met Galaxy-structuur (`meta/main.yml`, role-dependency).
- `terraform validate` + `ansible --syntax-check` als test-stap vóór deployment.
- Docker via `docker.io`, applicatie via Docker Compose.
