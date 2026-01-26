# Contributing

Thanks for your interest in contributing to **terraform-aws-dns-monitoring-free**.

## Scope & support

- **Free module** support is via **GitHub Issues**.
- For **Pro/Paid** offerings, please refer to Codreum support/SLA channels.

## Development prerequisites

- Terraform: recommended `>= 1.14.0` (or follow repo / example constraints).
- Terraform-docs: recommended `>= 0.20.0` (for auto-generated Inputs/Outputs in `modules/README.md`)
- Python 3 + `pre-commit` (recommended)
- AWS credentials only if you plan to run real plans/applies (not required for fmt/validate).

### Windows install tips (common)

If you use Chocolatey:

```powershell
# Run PowerShell as Administrator
choco install terraform -y
choco install terraform-docs -y
python -m pip install --user pre-commit
```

## Local checks (required before PR)

From repo root:

### 0) Install git hooks (recommended)

```bash
python -m pre_commit install
```

### 1) Format

```bash
terraform fmt -recursive
```

CI runs `terraform fmt -check -recursive` and will fail if formatting is needed.

### 2) Validate module

```bash
terraform -chdir=modules init -backend=false
terraform -chdir=modules validate
```

### 3) Validate examples

Run these for each example folder:

```bash
terraform -chdir=example/both-zone-vpc init -backend=false
terraform -chdir=example/both-zone-vpc validate

terraform -chdir=example/zone-only init -backend=false
terraform -chdir=example/zone-only validate

terraform -chdir=example/vpc-only init -backend=false
terraform -chdir=example/vpc-only validate
```

> Note: CI validates syntax and structure; apply requires real AWS resources/logs.

### 4) Keep terraform-docs in sync (modules/README.md)

This repo keeps **Inputs/Outputs** in sync via `terraform-docs` + pre-commit.

Run all hooks:

```bash
python -m pre_commit run -a
```

Or run only terraform-docs:

```bash
python -m pre_commit run terraform-docs -a
```

If you prefer running terraform-docs manually:

```bash
terraform-docs markdown table --output-file modules/README.md --output-mode inject ./modules
```

## Pull requests

1. Create a branch from `main`.
2. Make your change with focused commits.
3. Ensure CI passes.
4. Open a PR with a clear title and description:
   - What changed
   - Why it changed
   - How it was tested

## Release / versioning

- Use semver tags: `v0.1.0`, `v0.1.1`, etc.
- Don’t move existing tags to new commits (publish a new version instead).

## Code style

- Prefer readable Terraform: meaningful names, comments where needed.
- Keep dashboards stable (avoid noisy diffs).
- Avoid breaking changes in minor versions when possible.

## License

By submitting a PR, you agree your contribution may be redistributed under this repository’s license.
