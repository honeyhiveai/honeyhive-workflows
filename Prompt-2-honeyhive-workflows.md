# Prompt 2 — **`honeyhive-workflows` (catalog: reusable workflows + overlays)**

> **Goal:** Build the public/internal **catalog** repo that exposes reusable GHA workflows for Terragrunt and provides Terragrunt **overlays** (AWS now, Azure stub) with no tenant data.

**Create repo structure:**

```
honeyhive-workflows/
├─ actions/
│  ├─ setup-terragrunt/action.yml
│  └─ git-auth-github-app/action.yml
├─ overlays/
│  ├─ aws/root.hcl
│  └─ azure/root.hcl              # stub
├─ examples/
│  ├─ tenant-caller-apply.yml
│  ├─ tenant-caller-plan.yml
│  └─ tenant-terragrunt.hcl
├─ .github/workflows/
│  ├─ rwf-tg-plan.yml
│  ├─ rwf-tg-apply.yml
│  ├─ rwf-tg-destroy.yml
│  ├─ rwf-tg-drift.yml
│  ├─ pull_request.yml            # lint the repo itself
│  └─ tag_and_release.yml
├─ ACTION_VERSIONS.md
├─ README.md
└─ docs/WORKFLOWS.md
```

**Implement composite actions:**

* `setup-terragrunt`: installs TF **>=1.9.0** (pin binary) and TG (default **0.66.9**; input-configurable).
* `git-auth-github-app`: given `token`, run:

  ```
  git config --global url."https://x-access-token:${TOKEN}@github.com/".insteadOf "https://github.com/"
  git config --global url."https://x-access-token:${TOKEN}@github.com/".insteadOf "ssh://git@github.com/"
  git config --global url."https://x-access-token:${TOKEN}@github.com/".insteadOf "git@github.com:"
  ```

**Write AWS overlay `overlays/aws/root.hcl`:**

* Provide `locals` for `org, env, sregion, deployment, layer, service`.
* `generate "provider"` with default tags equal to the **common_tags** given.
* `remote_state` backend =

  * **bucket:** `honeyhive-federated-${local.sregion}-state` (internal default)
  * **key:** `${local.org}/${local.env}/${local.sregion}/${local.deployment}/${local.layer}/${local.service}/tfstate.json`
  * allow override of bucket via input (for BYOC).
* Small `assert()` to ensure `sregion` is one of known short codes if provided (do not hard fail for stubs).

**Azure overlay `overlays/azure/root.hcl` (stub):**

* `generate "provider"` for azurerm with features {}; placeholder remote state comments (no backend enforced yet).

**Reusable workflows (`on: workflow_call`):**

* **Common contract** (all `rwf-tg-*.yml`):

  * `inputs`:

    * `stack_path` (required): path in **caller repo** (e.g., `apiary/acme/usw2`).
    * `overlay_ref` (optional): tag/SHA of this repo; if set, checkout this repo into `_catalog/` so stacks can `include` the overlay path `${get_repo_root()}/_catalog/overlays/aws/root.hcl`.
    * `tg_args` (optional).
  * `secrets`:

    * `GH_APP_ID`, `GH_APP_PRIVATE_KEY`, `GH_APP_INSTALLATION_TOKEN_SALT` (or accept a single `GH_APP_TOKEN` if the caller minted it already).
    * `AWS_OIDC_ROLE` (optional).
  * `permissions`: `contents: read`, `id-token: write`, `pull-requests: read`.
  * `concurrency`: `group: tg-${{ inputs.stack_path }}`.

* **`rwf-tg-plan.yml`:**
  Steps:

  1. Checkout **caller repo**.
  2. Mint or receive GitHub App token → run `git-auth-github-app`.
  3. Optionally checkout this catalog repo (`overlay_ref`) into `_catalog/`.
  4. Run `setup-terragrunt`.
  5. Formatter | Validator | Security scan **in parallel** (e.g., `terragrunt hclfmt --recursive`, `tflint`, `tfsec`/`checkov`, `yamllint`).
  6. Linter step (shellcheck if any scripts).
  7. `terragrunt run-all plan` at `working-directory: ${{ inputs.stack_path }}`.
  8. Write a **compact plan summary** to the GHA **job summary**; upload full plan as an artifact.

* **`rwf-tg-apply.yml`:** identical prep; run `terragrunt run-all apply -auto-approve`.

* **`rwf-tg-destroy.yml`:** same but with `destroy`, restricted to `workflow_dispatch` + require reviewers.

* **`rwf-tg-drift.yml`:** scheduled `plan` with notification hook (leave webhook placeholder).

**Docs & Examples:**

* `examples/tenant-terragrunt.hcl` — shows **single include** of overlay from `_catalog` and a Terraform root module `source` pointing to `honeyhive-terraform` with `?ref=` pins.
* `docs/WORKFLOWS.md` — list inputs/secrets, environment protection guidance, sample caller workflows.

**Acceptance Criteria:**

* Runnable end-to-end against a sample `apiary/acme/usw2` stack.
* Summaries appear in job summaries; full plans uploaded.
* Concurrency prevents two applies to the same `stack_path`.

