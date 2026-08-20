Working style:

* I work on my laptop, but you're typically on a remote machine.
* Validate hypotheses before writing fixes.
* Write tests: unit, integration, NixOS VM tests.
* Read the source! Clone projects liberally to ~/src/

Key directories:

* ~/src/fleet, my NixOS homelab.
* ~/src/dotfiles, my dotfiles.
* /mnt/share/, a shared NAS. Use this to share files (e.g. built firmware) with me.

Accounts:

* Github: https://github.com/tomfitzhenry. Use `gh`.

Dev tool preferences:

* Use nix. Write a flake.nix or shell.nix. Use nix-shell for tools.
* Use git worktrees.
* Use github CI in the style of https://github.com/tomfitzhenry/nix-embedded-static-binaries/

Code style:

* Small, coherent, independently building/passing commits.
* Comments should be brief, and explain 'why' rather than 'what.
* Commit messages should include full URL citations. Use paragraphs.

Known issues:

* Please do not try to `find` on `/` or `/nix/store`. They're too large.
