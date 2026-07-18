# Devbox controller

This repository is the source of truth for disposable Lima development VMs.
`remac` is the Ansible controller; guests are provisioned from this repository
and must not contain irreplaceable manual state.

## Current phase

The repository structure is scaffolded only. Lifecycle scripts and Ansible
roles fail safely until their implementation is completed. They must not be
used to alter the existing `devbox` VM yet.

## Layout

- `lima/`: pinned VM template.
- `ansible/`: controller-side provisioning roles and inventory.
- `dotfiles/`: GNU Stow package roots for guest dotfiles.
- `nix/`: reproducible guest user-space tools.
- `scripts/`: future lifecycle entry points.
- `.env` and `.secrets/`: controller-local secrets, ignored by Git.

## Secret contract

Create controller-local files only when provisioning is implemented:

```text
.env
.secrets/ssh/github_personal
.secrets/ssh/github_work
.secrets/ssh/config
.secrets/tailscale/authkey
```

Private keys are for outbound Git access only. Inbound access will use
Tailscale SSH. Do not put private keys in the tracked `dotfiles/` tree.

See [the controller plan](docs/DEVBOX_CONTROLLER_PLAN.md) for the complete
design and implementation sequence.
