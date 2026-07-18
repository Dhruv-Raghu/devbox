# Devbox controller

This repository is the source of truth for disposable Lima development VMs.
`remac` is the Ansible controller; guests are provisioned from this repository
and must not contain irreplaceable manual state.

## Lifecycle

The scripts run from `remac`; use a distinct instance name while testing so the
existing `devbox` VM remains untouched. `create` only creates a Lima VM.
`provision` applies every Ansible role, and is safe to re-run after changing
packages or dotfiles.

```bash
scripts/create devbox-remac
scripts/provision devbox-remac
scripts/verify devbox-remac
scripts/shell devbox-remac
```

Destroying a VM is intentionally explicit:

```bash
DEVBOX_ALLOW_DESTROY=1 scripts/destroy devbox-remac
```

## Layout

- `lima/`: pinned VM template.
- `ansible/`: controller-side provisioning roles and inventory.
- `dotfiles/`: GNU Stow package roots for guest dotfiles.
- `nix/`: reproducible guest user-space tools.
- `scripts/`: lifecycle entry points.
- `.env` and `.secrets/`: controller-local secrets, ignored by Git.

## Secret contract

Create these ignored controller-local files before first provisioning:

```text
.env
.secrets/ssh/id_ed25519_github_dhruv
.secrets/ssh/id_ed25519_github_dhruv.pub
.secrets/ssh/config
```

`.env` must contain `TS_AUTHKEY=...` for first Tailscale enrollment. It is not
needed for later converges of an already enrolled VM. Use a reusable auth key
only if you intend to destroy and recreate VMs without replacing the key.

Private keys are for outbound Git access only. Inbound access will use
Tailscale SSH. Do not put private keys in the tracked `dotfiles/` tree.

See [the controller plan](docs/DEVBOX_CONTROLLER_PLAN.md) for the complete
design.
