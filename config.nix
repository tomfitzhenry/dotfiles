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
    gittuf
    lefthook
    nushell
    openssh # since SteamOS's openssh has no libfido2.so
    p7zip
    restic
    wormhole-william

    curl
    dig
    jq
    ncdu
    ripgrep
    tmux
    tree

    # Passwords
    passage
    age-plugin-yubikey
    yubikey-manager

    # LSP
    bash-language-server
    go
    gopls
    nixd

    # Nix
    nixfmt-tree
    nixos-generators
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
