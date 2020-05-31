install:
	stow -t ~ dotfiles

test:
	nix-build tests.nix

