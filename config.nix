let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  nix-maid = import sources.nix-maid;
in
nix-maid pkgs {
  file.home.".config/emacs/init.el".source = ./dotfiles/.config/emacs/init.el;
  file.home.".config/nix/nix.conf".source = ./dotfiles/.config/nix/nix.conf;
  file.home.".config/sway".source = ./dotfiles/.config/sway;
  file.home.".config/waybar/".source = ./dotfiles/.config/waybar;

  packages = with pkgs; [
    git
    shpool
    gittuf
    lefthook
    mg
    nushell
    openssh # since SteamOS's openssh has no libfido2.so
    pomerium-cli
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

    # WM
    alacritty
    font-awesome
    networkmanagerapplet
    pasystray
    waybar

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
