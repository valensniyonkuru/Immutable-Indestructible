# Immutable & Indestructible Pipeline

Secure software supply chain for FinCorp. Every dependency is proxied through
CodeArtifact, every Docker image is immutably stored in ECR, and the database is
backed up nightly with an automatic cross-region copy to `us-west-2`.

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # GitHub Actions pipeline
├── app/
│   ├── index.js                   # Express.js application
│   └── package.json               # Node.js dependencies
├── terraform/
│   ├── main.tf                    # Terraform version block + all locals
│   ├── providers.tf               # AWS provider config (primary + secondary)
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Post-apply outputs
│   ├── ecr.tf                     # Amazon ECR repository + lifecycle policy
│   ├── codeartifact.tf            # CodeArtifact domain + npm/pip repositories
│   ├── rds.tf                     # RDS PostgreSQL instance + subnet group
│   ├── backup.tf                  # AWS Backup vaults, plan, and cross-region copy
│   ├── security_group.tf          # VPC security group + data sources
│   └── iam.tf                     # IAM role for AWS Backup
├── Dockerfile                     # Container build instructions
├── requirements.txt               # Python dependency for pip proxy demo
├── .gitignore
└── README.md
```

---

## Architecture

```
GitHub Actions
      │
      ├─► CodeArtifact (fincorp-domain)
      │       ├── fincorp-npm-proxy  ──► public:npmjs
      │       └── fincorp-pypi-proxy ──► public:pypi
      │
      ├─► ECR (fincorp-app-repo)
      │       └── IMMUTABLE tags, scan-on-push, lifecycle expiry
      │
      └─► [Terraform deploys separately]
              │
              ├── RDS PostgreSQL (us-east-1, default VPC)
              │       └── Security group: port 5432 open to VPC CIDR only
              │
              └── AWS Backup
                      ├── Primary vault: fincorp-backup-vault     (us-east-1)
                      └── DR vault:      fincorp-backup-vault-dr  (us-west-2)
                              └── Daily copy via copy_action
```

**AWS Account:** `195275642256`
**Primary region:** `us-east-1`
**DR region:** `us-west-2`
**Networking:** default VPC + default subnets in `us-east-1`

---

## Terraform Infrastructure

### ECR — `terraform/ecr.tf`

| Setting | Value |
|---------|-------|
| Repository name | `fincorp-app-repo` |
| Tag mutability | `IMMUTABLE` — existing tags cannot be overwritten |
| Scan on push | `true` — Basic scanning runs on every image push |
| Lifecycle policy | Untagged images expire after 30 days |

### CodeArtifact — `terraform/codeartifact.tf`

| Resource | Name | Upstream |
|----------|------|----------|
| Domain | `fincorp-domain` | — |
| npm repo | `fincorp-npm-proxy` | `public:npmjs` |
| pip repo | `fincorp-pypi-proxy` | `public:pypi` |

AWS enforces one external connection per repository, so npm and pip each get
their own repository inside the same domain.

### RDS PostgreSQL — `terraform/rds.tf`

| Setting | Value |
|---------|-------|
| Identifier | `fincorp-rds-primary` |
| Engine | PostgreSQL 15.4 |
| Instance class | `db.t4g.small` |
| Storage | 20 GB |
| Public access | `false` |
| Automated backups | 7-day retention (native RDS) |

### Security Group — `terraform/security_group.tf`

- Name: `fincorp-rds-postgres-sg`
- Ingress: port `5432/tcp` from the default VPC CIDR only
- Egress: unrestricted outbound

### AWS Backup — `terraform/backup.tf`

| Setting | Value |
|---------|-------|
| Schedule | `cron(0 5 * * ? *)` — 05:00 UTC daily |
| Primary vault | `fincorp-backup-vault` (us-east-1) |
| DR vault | `fincorp-backup-vault-dr` (us-west-2) |
| Retention | 30 days in both vaults |
| Copy action | Automatic cross-region copy on each recovery point |

The IAM role `fincorp-aws-backup-role` (`terraform/iam.tf`) carries
`AWSBackupServiceRolePolicyForBackup` and `AWSBackupServiceRolePolicyForRestores`.

---

## Deployment

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured for account `195275642256`
- IAM permissions: ECR, CodeArtifact, RDS, Backup, IAM, VPC read

### Terminal commands

```bash
# 1. Move into the terraform directory
cd terraform

# 2. Download providers
terraform init

# 3. Preview — always review before applying
terraform plan -var "rds_password=YourSecurePassword123!"

# 4. Apply
terraform apply -var "rds_password=YourSecurePassword123!" -auto-approve

# 5. Print the key outputs
terraform output ecr_repository_uri
terraform output rds_endpoint
terraform output backup_vault_primary_arn
terraform output backup_vault_secondary_arn
```

> Tip: set the environment variable `TF_VAR_rds_password=YourSecurePassword123!`
> in your shell to avoid repeating `-var` on every command.

### Trigger the pipeline

Push a commit to `main` or a `release/**` branch. The workflow fires automatically.

---

## GitHub Secrets — Required Before First Pipeline Run

Add these in **GitHub → Settings → Secrets and variables → Actions → New repository secret**:

| Secret name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | IAM access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM secret access key |

The IAM user behind those credentials needs at minimum:

- `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`,
  `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`,
  `ecr:DescribeRepositories`, `ecr:CreateRepository`
- `ecr:StartImageScan`, `ecr:DescribeImageScanFindings`
- `codeartifact:GetAuthorizationToken`, `codeartifact:GetRepositoryEndpoint`
- `sts:GetServiceBearerToken` (required by the CodeArtifact login command)

---

## CI/CD Pipeline

File: `.github/workflows/ci-cd.yml`

**Triggers:** push to `main` or `release/**`; pull requests targeting `main`; manual dispatch.

### Pipeline steps

| # | Step | What it does |
|---|------|-------------|
| 1 | Checkout | Fetches repo contents |
| 2 | Setup Node.js 20 | Runtime for the app |
| 3 | Setup Python 3.12 | Runtime for the vulnerability gate script |
| 4 | Configure AWS credentials | Reads `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` from GitHub Secrets |
| 5 | Resolve account ID | `aws sts get-caller-identity` → `$AWS_ACCOUNT_ID` |
| 6 | Authenticate npm → CodeArtifact | `aws codeartifact login --tool npm --repository fincorp-npm-proxy` |
| 7 | Authenticate pip → CodeArtifact | `aws codeartifact login --tool pip --repository fincorp-pypi-proxy` |
| 8 | `npm install` | Packages fetched through the CodeArtifact npm proxy |
| 9 | `pip install` | Packages fetched through the CodeArtifact pip proxy |
| 10 | ECR login | Docker authenticated to `195275642256.dkr.ecr.us-east-1.amazonaws.com` |
| 11 | Ensure repo exists | Idempotent create-if-absent with `IMMUTABLE` + `scan_on_push` |
| 12 | Build + tag | Image tagged with `github.sha` |
| 13 | Push to ECR | Image stored with immutable tag |
| 14 | Start ECR scan | `aws ecr start-image-scan` |
| 15 | Wait for scan | Polls every 10 s, times out after 3 min |
| 16 | Vulnerability gate | Fails the build on any `HIGH` or `CRITICAL` CVE |

---

## Disaster Recovery Simulation

### Scenario: `us-east-1` RDS instance is unavailable

**Step 1 — Confirm a recovery point exists in `us-west-2`**

```bash
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name fincorp-backup-vault-dr \
  --region us-west-2 \
  --query 'RecoveryPoints[*].{ARN:RecoveryPointArn,Status:Status,Created:CreationDate}' \
  --output table
```

**Step 2 — Capture the latest recovery point ARN**

```bash
RECOVERY_POINT=$(aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name fincorp-backup-vault-dr \
  --region us-west-2 \
  --query 'RecoveryPoints | sort_by(@, &CreationDate) | [-1].RecoveryPointArn' \
  --output text)

echo "Restoring from: $RECOVERY_POINT"
```

**Step 3 — Start the restore job**

```bash
aws backup start-restore-job \
  --recovery-point-arn "$RECOVERY_POINT" \
  --iam-role-arn arn:aws:iam::195275642256:role/fincorp-aws-backup-role \
  --region us-west-2 \
  --metadata '{
    "DBInstanceIdentifier": "fincorp-rds-dr-restore",
    "DBSubnetGroupName":    "default",
    "Engine":               "postgres",
    "PubliclyAccessible":   "false"
  }'
```

**Step 4 — Monitor until `COMPLETED`**

```bash
aws backup list-restore-jobs \
  --region us-west-2 \
  --query 'RestoreJobs[*].{ID:RestoreJobId,Status:Status,Completed:CompletionDate}' \
  --output table
```

**Step 5 — Get the restored endpoint and reconnect the application**

```bash
aws rds describe-db-instances \
  --db-instance-identifier fincorp-rds-dr-restore \
  --region us-west-2 \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

Update the application connection string to point to this new endpoint.

---

## Live Walkthrough Script

### 1. Architecture overview (2 min)

> "FinCorp runs a software supply chain with two guarantees: every dependency
> comes from a controlled, audited source, and every Docker image is permanently
> immutable once it reaches ECR. The database in `us-east-1` is backed up every
> night, and each backup is automatically copied to `us-west-2` so we can
> restore in a different region with a single CLI command."

### 2. CodeArtifact — Trusted dependency proxy (2 min)

- Open `terraform/codeartifact.tf`
- "We provision two repositories inside `fincorp-domain` — one for npm, one
  for pip. AWS enforces one external connection per repository, so two repos is
  the correct design."
- Open `.github/workflows/ci-cd.yml` — point to the two `aws codeartifact login` steps
- "When `npm install` runs, npm is transparently redirected to
  `fincorp-npm-proxy`. Every package download is cached and logged in
  CodeArtifact — nothing reaches the internet directly from the build runner."

### 3. ECR — Immutable images + vulnerability gate (3 min)

- Open `terraform/ecr.tf`
- "Tag mutability is `IMMUTABLE`. If the workflow tries to push the same
  commit SHA twice, ECR rejects the second push outright. A published image
  can never be silently replaced."
- Show steps 14–16 in the workflow
- "After every push, we wait for ECR's Basic scan to finish, then a Python
  script reads the severity counts from the API. One `HIGH` or `CRITICAL` CVE
  is enough to call `sys.exit(1)` and halt the run before any downstream
  service can pull the image."

### 4. RDS + Security Group (1 min)

- Open `terraform/rds.tf` and `terraform/security_group.tf`
- "`publicly_accessible = false` — the instance has no internet-facing address.
  Port 5432 is open only to the VPC CIDR, enforced at the security group level."

### 5. AWS Backup — Indestructible data (2 min)

- Open `terraform/backup.tf`
- "The plan fires at 05:00 UTC daily. The `copy_action` block inside the rule
  writes a second recovery point directly into the DR vault in `us-west-2`.
  No manual step is needed — every primary backup automatically gets a DR copy."
- Walk through the five DR simulation commands above

### 6. End-to-end pipeline run (2 min)

- Open a recent GitHub Actions workflow run
- Walk through each job step in order
- Highlight step 16 (vulnerability gate) as the enforcement mechanism that
  keeps unsafe images out of the registry

---

## Notes

- No credentials are hardcoded anywhere. All secrets live in GitHub Secrets
  and are consumed as `${{ secrets.* }}` references.
- `rds_password` has no default value. Terraform will refuse to plan without
  it, preventing accidental use of a weak password.
- The secondary backup vault is named `fincorp-backup-vault-dr` to distinguish
  it from the primary vault in the AWS console and CLI output.
