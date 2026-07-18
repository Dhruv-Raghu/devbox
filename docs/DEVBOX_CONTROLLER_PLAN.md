# Controller-Managed Devbox Plan

## Goal

Build a reproducible dev sandbox where `remac` is the controller and Lima VMs are disposable targets. The controller repository creates, provisions, verifies, and destroys Ubuntu devboxes. A VM must contain no manually maintained state.

## Non-goals

- Do not implement this plan yet.
- Do not place secrets in Git.
- Do not disable SSH host-key verification.
- Do not depend on guest-side manual configuration.

## Fixed decisions

- Controller: `remac`, macOS 12.7.6.
- VM platform: Lima + QEMU, Intel/x86_64 Ubuntu.
- Provisioner: Ansible runs on `remac`, not inside the VM.
- Dotfiles: GNU Stow.
- Inbound access: Tailscale SSH.
- Outbound Git access: dedicated VM-only SSH keys.
- Tailscale node: static, non-ephemeral, tagged `tag:devbox`.
- Nix: user-space developer tools; APT/Ansible: OS packages/services.

## Preconditions

Document and validate Lima/QEMU/Ansible/Python versions, Ubuntu image URL and digest, guest username, guest sudo policy, and required controller commands (`ssh`, `scp` or `rsync`, `git`, `jq`, and `limactl`).

Pin the guest user:

```yaml
lima_guest_user: dhruv
```

Resolve the actual guest home directory from Ansible facts; do not hard-code `/home/dhruv.guest`.

## Repository layout

```text
devbox/
  README.md
  Makefile
  .gitignore
  .env.example
  lima/dev.yaml
  ansible/
    ansible.cfg
    inventory/lima_inventory.py
    playbooks/devbox.yml
    group_vars/{all.yml,versions.yml}
    roles/{bootstrap,base,tailscale,git_keys,dotfiles,nix,verify}
  dotfiles/{zsh,p10k,git,tmux}
  nix/{flake.nix,flake.lock}
  scripts/{create,provision,verify,shell,destroy}
```

Ignored controller-local material:

```text
.env
.secrets/
.runtime/
```

Recommended secret layout:

```text
.secrets/
  ssh/{github_personal,github_work,config}
  tailscale/authkey
```

Use `0700` for secret/runtime directories and `0600` for private keys.

## Responsibility boundaries

Lima creates only a reachable Ubuntu guest with bootstrap SSH. Ansible on `remac` is authoritative for all guest configuration. Nix manages reproducible user-space developer tools. APT/Ansible manages OS functionality such as OpenSSH, sudo, certificates, curl, Git, Zsh, Stow, libraries, and Tailscale.

## Runtime state and SSH trust

Keep generated state under `.runtime/<instance>/`, including `inventory.json`, `known_hosts`, logs, and locks.

The inventory helper must obtain current connection data from Lima-supported output first, use `~/.lima/<instance>/ssh.config` only as a validated fallback, and fail when the VM is stopped/unreachable.

Use a per-instance runtime `known_hosts` file. Populate it from the verified Lima guest path, rotate/remove it on recreate/destroy, and never use `StrictHostKeyChecking=no`.

## Secrets

Dedicated outbound Git keys live only in ignored controller `.secrets/ssh`. Ansible copies only named keys into guest `~/.ssh` with correct ownership/permissions and `no_log: true`. Do not deploy everyday laptop keys or Stow private keys.

Keep the Tailscale key only in ignored `.env` or `.secrets/tailscale/authkey`. Do not expose it in command arguments, logs, process listings, or error output. Prefer a temporary mode-`0600` file with `--auth-key=file:<path>`, then delete it.

Initially use a reusable, pre-authorized, non-ephemeral key scoped to `tag:devbox`; consider controller-side OAuth-minted short-lived keys later.

## Tailscale

Use one variable, such as `devbox-remac`, for the Lima instance name, Ubuntu hostname, and Tailscale hostname. Do not reuse an active MagicDNS name.

Configure a static node with `tag:devbox` and Tailscale SSH. Retain guest OpenSSH for Lima and Ansible bootstrap.

Tailnet policy is an external prerequisite: it must allow `tag:devbox` assignment and the intended user to Tailscale-SSH to that tag.

Destroy must attempt guest logout when reachable, delete only the named VM, and report if controller-side Tailscale API/admin cleanup is still required. Guest logout is not guaranteed cleanup for a static node.

## Ansible role order

```text
bootstrap SSH + sudo validation
→ base
→ Tailscale
→ Git keys
→ dotfiles
→ Nix
→ verify
```

### bootstrap

- Verify bootstrap SSH, guest user, and supported noninteractive `become` behavior.
- Gather facts, including actual guest home.
- Fail before changes if the guest contract is wrong.

### base

Manage a declared APT list initially containing:

```yaml
base_apt_packages:
  - ca-certificates
  - curl
  - git
  - openssh-server
  - sudo
  - stow
  - zsh
```

Enable OpenSSH, create user directories, and do not change the login shell until dotfiles validate.

### tailscale

Install Tailscale from a defined source, enable `tailscaled`, join/configure idempotently, and verify with `tailscale status --json`.

### git_keys

Create secure `~/.ssh`, deploy dedicated outbound keys/config aliases using `IdentitiesOnly yes`, disable agent forwarding, maintain Git-host known keys deliberately, and test that each alias authenticates as the intended account.

Explicitly choose either unencrypted least-privilege keys for noninteractive Git or an agent/passphrase workflow.

### dotfiles

Deploy tracked dotfiles to `~/.local/share/devbox-dotfiles`, use `stow --simulate` before `stow --restow`, and fail clearly on conflicts. Never silently overwrite. Pin Oh My Zsh and Powerlevel10k to immutable commit SHAs; do not use their installer scripts. Validate clean interactive Zsh before optional `chsh -s /usr/bin/zsh`.

### nix

Use a pinned, checksum-verified, noninteractive multi-user Nix installation method; do not use unpinned curl-to-shell. Record installer version/checksum in `versions.yml`, enable/verify the daemon, persist `experimental-features = nix-command flakes`, deploy the flake/lockfile, build before profile replacement, and verify tools in a fresh login shell.

## Deployment model

The controller repo is authoritative. Ansible deploys only required tracked artifacts to stable guest directories. A guest clone can remain for reference but must not be required for provisioning.

## Lifecycle interface

```sh
./scripts/create devbox-remac
./scripts/provision devbox-remac
./scripts/verify devbox-remac
./scripts/shell devbox-remac
./scripts/destroy devbox-remac
```

Scripts must use Bash safely (`set -euo pipefail`), avoid macOS-incompatible GNU assumptions, validate instance names, and hold per-instance locks.

`create` validates/starts the VM and waits for bootstrap SSH. `provision` resolves inventory, validates trust/sudo, loads secrets safely, and runs roles. `verify` checks Lima SSH, Tailscale SSH, services, Git, Stow, Zsh, and Nix. `destroy` cleans only the named instance and reports static-node Tailscale cleanup status.

## Idempotency and rollback

Each role must document drift detection, correction, partial-failure outcome, and rerun safety. Build Nix before replacing its profile; do not switch shell until Zsh validates; dry-run Stow before applying it.

Do not make state-changing changes to the current working VM until repository state is committed, a rollback/snapshot strategy exists, and the workflow passes on `devbox-test`.

## Test matrix

Required tests:

- Fresh create/provision on `devbox-test`.
- A second provision run is idempotent.
- Recreating the same instance handles changed host keys safely.
- Stopped VM fails cleanly.
- Missing/expired Tailscale key or bad ACL fails without secret leaks.
- Git authentication failure identifies the affected alias.
- Stow conflict does not overwrite files.
- Interrupted destroy reports static-node cleanup status.
- A fresh controller clone plus local secrets recreates a VM.
- Fresh login shell exposes Nix tools and valid Zsh configuration.
- Lima bootstrap SSH and Tailscale SSH both work independently.

## Migration sequence

1. Preserve the working VM and `lima/dev.yaml`.
2. Add repository structure and safety scaffolding.
3. Implement read-only dynamic inventory and host-key handling.
4. Create `devbox-test`.
5. Implement/test roles in order: bootstrap, base, Tailscale, Git keys, dotfiles, Nix.
6. Run the lifecycle/failure test matrix.
7. Only then migrate or replace the current `devbox`.
