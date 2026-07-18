# Nix tooling

This flake defines the reproducible user-space developer tools for devbox.

After Nix is installed, run the following from this directory:

```sh
nix profile install .#devbox-tools
```

For a temporary shell containing the same tool set:

```sh
nix develop
```

Update `tools` in `flake.nix`, then run `nix flake update` deliberately and commit the resulting `flake.lock`.
