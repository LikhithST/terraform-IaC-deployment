Yes, that is a standard pattern for managing secrets across multiple stages (like `dev`, `staging`, and `prod`) in GitHub Actions.

By pairing GitHub Environments with `TF_VAR_` environment variables, you can use the exact same Terraform code and workflow file while swapping out the underlying secrets depending on which environment is being deployed.

### How It Works

1. **Create GitHub Environments:** In your repository **Settings > Environments**, create environments such as `dev` and `prod`.
2. **Add Environment Secrets:** Inside each environment, add a secret with the same name (for example, `DB_PASSWORD`), holding the respective password for that environment.
3. **Map to `TF_VAR_` in Your Workflow:** Reference the GitHub Environment in your job, and map the secret to a `TF_VAR_` environment variable.

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [ main ]

jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    # Targets the "prod" GitHub Environment
    environment: prod
    
    env:
      # Maps the GitHub Environment secret to Terraform's input variable
      TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
      
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      
      - run: terraform init
      - run: terraform apply -auto-approve

```

### Watch Out for Precedence Conflicts

Because `TF_VAR_` has lower precedence than `.tfvars` files, keep these two rules in mind so your GitHub Secrets are not accidentally ignored:

* **Do not put secret placeholders in `terraform.tfvars` or `*.auto.tfvars`:** If you have `db_password = "changeme"` in `terraform.tfvars`, Terraform will use `"changeme"` instead of your `TF_VAR_db_password` secret. Leave secret variables completely out of auto-loaded `.tfvars` files.
* **Safe to combine with non-secret `-var-file` flags:** You can safely run `terraform apply -var-file="prod.tfvars"` for non-sensitive settings (like instance sizes or region names) alongside `TF_VAR_db_password`, as long as `db_password` is not defined inside `prod.tfvars`.

### Additional Benefits of GitHub Environments

Using GitHub Environments also gives you built-in deployment protection rules, such as requiring manual reviewer approval before the `prod` job can access the secrets and run `terraform apply`.