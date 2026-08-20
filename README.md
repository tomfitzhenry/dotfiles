# dotfiles

Nix-managed dotfiles and user environment, applied with [nix-maid](https://github.com/nix-maid/nix-maid).

## Layout

| Path | Description |
|------|-------------|
| `config.nix` | Main nix-maid config: home files, packages, and systemd user units. Takes a `role` argument (`"desktop"` or `"server"`) to toggle desktop-only packages and config. |
| `dotfiles/` | Raw dotfiles symlinked into `$HOME`. |
| `npins/` | Pinned sources used by `config.nix`. |
| `keyboards/` | QMK keyboard layouts (`ergodox-ez`, `silakka54`). |
| `.forgejo/` | Forgejo CI workflows. |
| `apply` | Installs the config: `nix-env -if config.nix` then activates. |
| `update` | Runs `npins update` to refresh pins. |
