# Devbox controller

This repository is the source of truth for `devbox-remac`, the persistent
Lima development VM hosted on `remac`. `remac` is only the controller; the VM
is disposable and must not contain configuration that cannot be recreated from
this repository and its ignored local secrets.

## What this creates

`devbox-remac` is an Ubuntu 24.04 Lima VM with 2 vCPUs, 4 GiB of memory, and
an 80 GiB sparse virtual disk. Provisioning installs the declared APT and Nix
tools, Tailscale SSH, the dedicated outbound Git identity, Oh My Zsh,
Powerlevel10k, Omnigent, and the GNU Stow dotfiles in this repository.

Inbound access is through Tailscale SSH. The deployed Git private key is only
for outbound Git access from the VM.

## One-time controller prerequisites

Run these steps on `remac`, in this repository:

```bash
cd /Users/dhruv/ReMac/devbox
git pull --ff-only
ansible-playbook --version
limactl --version
```

The controller requires Lima, Ansible, and its existing QEMU runtime. On this
machine they are installed through the established MacPorts/Lima setup.

Create the following ignored local files. They must never be committed:

```text
.env
.secrets/ssh/config
.secrets/ssh/id_ed25519_github_dhruv
.secrets/ssh/id_ed25519_github_dhruv.pub
```

Every regular file directly in `.secrets/ssh/` is deployed to the guest’s
`~/.ssh/` directory on each provisioning run. Add further private/public key
pairs there—for example `id_ed25519_github_aadi` and
`id_ed25519_github_aadi.pub`—then update `.secrets/ssh/config`; the next
`scripts/provision devbox-remac` copies them across. This directory is ignored
by Git, so it is your controller-local source of truth for outbound SSH
credentials.

Set the Tailscale authentication key in `.env`:

```bash
TS_AUTHKEY=tskey-auth-...
```

The key must be authorized to apply `tag:devbox`. Prefer a reusable,
non-ephemeral key if you want to destroy and later recreate this VM without
replacing the key. The key is only needed for its first Tailscale enrollment;
repeat provisioning of an enrolled VM does not use it.

The SSH config must define the dedicated Git alias used by the VM:

```sshconfig
Host github-dhruv
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_dhruv
  IdentitiesOnly yes
```

Keep the private key restricted to its owner:

```bash
chmod 700 .secrets .secrets/ssh
chmod 600 .secrets/ssh/config .secrets/ssh/id_ed25519_github_dhruv
chmod 644 .secrets/ssh/id_ed25519_github_dhruv.pub
```

## Create the real VM

Do not run this while another Lima instance is consuming the host’s limited
memory. From a clean state, run:

```bash
cd /Users/dhruv/ReMac/devbox
scripts/create devbox-remac
scripts/shell devbox-remac cloud-init status --wait
scripts/provision devbox-remac
scripts/verify devbox-remac
```

`create` starts the VM only. `provision` applies every managed role. The
`cloud-init` wait prevents package-manager contention during first boot.
`verify` safely re-converges the VM and checks services, Nix tools, dotfiles,
and outbound Git authentication.

On completion, connect through Tailscale:

```bash
ssh dhruv@devbox-remac
```

Or use Lima’s local console path from `remac`:

```bash
scripts/shell devbox-remac
```

## Routine changes

Keep desired state in Git, then re-run provisioning:

- Add OS packages to `ansible/group_vars/all.yml` under `base_apt_packages`.
- Add developer tools to `nix/flake.nix`. Update and commit `nix/flake.lock`
  when changing Nix inputs.
- Update the pinned Omnigent release and installer revision/checksum in
  `ansible/group_vars/versions.yml`; provisioning installs it through its
  verified upstream installer.
- Add shell, Git, or terminal configuration under `dotfiles/`; GNU Stow deploys
  these into the guest home directory.
- Replace the dedicated outbound Git keys only in ignored `.secrets/ssh/`.

Apply and validate a change with:

```bash
scripts/provision devbox-remac
scripts/verify devbox-remac
```

Commit and push tracked configuration changes. Never commit `.env` or
`.secrets/`.

## Rebuild or destroy

Destroying the VM deletes its disk and all guest-local state. Confirm tracked
configuration and ignored secrets are current before doing so:

```bash
DEVBOX_ALLOW_DESTROY=1 scripts/destroy devbox-remac
```

After destruction, remove the old node from the Tailscale admin console if it
is still listed. Recreate using the **Create the real VM** steps above. A new
or reusable `TS_AUTHKEY` is required for the new node enrollment.

## Repository layout

- `lima/`: Lima VM template.
- `ansible/`: controller-side provisioning roles and inventory.
- `dotfiles/`: GNU Stow package roots for guest dotfiles.
- `nix/`: pinned, reproducible guest user-space tools.
- `scripts/`: lifecycle commands.
- `.env` and `.secrets/`: ignored controller-local secrets.

See [the controller plan](docs/DEVBOX_CONTROLLER_PLAN.md) for the underlying
design decisions.
