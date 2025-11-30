let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  nix-maid = import sources.nix-maid;
in
nix-maid pkgs {
  file.home.".config/emacs/init.el".source = ./dotfiles/.config/emacs/init.el;
  file.home.".config/nix/nix.conf".source = ./dotfiles/.config/nix/nix.conf;

  packages = with pkgs; [
    git
    nushell
    openssh # since SteamOS's openssh has no libfido2.so
    p7zip
    restic
    wormhole-william
    ghostty

    curl
    dig
    tree
    tmux

    # Passwords
    passage
    age-plugin-yubikey
    yubikey-manager

    # LSP
    bash-language-server
    nixd

    # Nix
    nixfmt-rfc-style
    npins

    (emacs-pgtk.pkgs.withPackages (
      with emacsPackages;
      [
        eat
        diff-hl
        magit

        # tree-sitter
        treesit-grammars.with-all-grammars
        markdown-ts-mode
        nix-ts-mode
        nushell-ts-mode
      ]
    ))
  ];
}
