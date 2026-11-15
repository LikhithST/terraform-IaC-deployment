Terraform loads input variables in a strict order of precedence. Later sources override earlier ones, meaning the item at the bottom of the list always wins.

### Variable Precedence Order (Lowest to Highest)

1. **Variable `default` values:** Defined inside the `variable` block in your `.tf` files.
2. **Environment variables:** Any variable prefixed with `TF_VAR_` (e.g., `TF_VAR_db_password`).
3. **`terraform.tfvars` file:** Automatically loaded if present in the working directory.
4. **`terraform.tfvars.json` file:** Automatically loaded if present (overrides `terraform.tfvars`).
5. **Any `*.auto.tfvars` or `*.auto.tfvars.json` files:** Automatically loaded in lexical (alphabetical) order.
6. **Command-line flags (`-var` and `-var-file`):** Processed in the exact order they are passed on the CLI. If you pass `-var-file="prod.tfvars"` followed by `-var="db_password=123"`, the `-var` flag wins.

If a variable has no `default` and is not provided by any of the sources above, Terraform prompts you to enter it interactively at the command line (unless `-input=false` is set, which causes an error).

---

### How This Applies to Secrets

* **Local Overrides:** Because `-var` and `-var-file` have the highest precedence, you can pass a git-ignored local file (e.g., `terraform apply -var-file="secrets.tfvars"`) to override any defaults during local testing.
* **CI/CD Gotcha:** Because `terraform.tfvars` and `*.auto.tfvars` override `TF_VAR_` environment variables, make sure no dummy or placeholder values for your secrets exist in those files. If `db_password = "placeholder"` is sitting in `terraform.tfvars`, Terraform will ignore your `TF_VAR_db_password` environment variable in CI/CD.




Put `env` at the **step level** for secrets, and at the **job level** for non-sensitive configuration (like `AWS_REGION` or `TF_WORKSPACE`).

### Why Step Level is Better for Secrets

* **Least Privilege (Blast Radius):** In a typical Terraform workflow, you run steps like `actions/checkout`, `terraform fmt -check`, `terraform validate`, `terraform plan`, and `terraform apply`. A formatting check or third-party action does not need access to your database password. Scoping secrets to only the steps that need them prevents third-party actions in earlier steps from reading `process.env` and exfiltrating your credentials.
* **Cleaner Maintenance:** You only inject secrets into `terraform plan`, `terraform apply`, or `terraform destroy`.

### Example Structure

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod
    
    # Job-level: Safe for non-sensitive config shared across all steps
    env:
      TF_IN_AUTOMATION: "true"
      AWS_REGION: "ap-south-1"

    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3

      # No secrets needed for init or validate
      - run: terraform init
      - run: terraform validate

      # Step-level: Secrets injected ONLY where Terraform evaluates variables
      - name: Terraform Plan
        env:
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
        run: terraform plan -out=tfplan

      # Note: Applying a saved plan file (tfplan) already contains the resolved
      # variable values, so you only need TF_VAR_ here if running apply directly
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan

```

### When Job Level Makes Sense

If your job is minimal and contains *only* trusted first-party steps (`checkout`, `setup-terraform`, `init`, `plan`, `apply`), setting `env` at the job level is fine and avoids repeating the block across `plan`, `apply`, and `destroy`. However, the moment you introduce third-party actions (like linting tools, PR comment bots, or security scanners) into the same job, move your secrets down to the step level.