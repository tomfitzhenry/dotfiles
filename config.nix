let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
        "claude-code"
      ];
  };
  nix-maid = import sources.nix-maid;
in
nix-maid pkgs {
  file.home.".bashrc".source = ./dotfiles/.bashrc;
  file.home.".gitconfig".source = ./dotfiles/.gitconfig;
  file.home.".config/emacs/init.el".source = ./dotfiles/.config/emacs/init.el;
  file.home.".config/nix/nix.conf".source = ./dotfiles/.config/nix/nix.conf;
  file.home.".config/sway".source = ./dotfiles/.config/sway;
  file.home.".config/waybar/".source = ./dotfiles/.config/waybar;

  packages = with pkgs; [
    git
    jujutsu
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

    niri
    noctalia-shell

    curl
    dig
    fzf
    jq
    ncdu
    ripgrep
    tree

    # Desktop applications
    brave
    claude-code
    signal-desktop
    foliate

    # WM
    ghostty
    font-awesome
    wl-clipboard
    xwayland-run

    # Passwords
    passage
    age-plugin-yubikey
    yubikey-manager

    # LSP
    bash-language-server
    go
    gopls
    nixd

    # LLM
    ollama
    pi-coding-agent

    # Nix
    nixfmt-tree
    nixos-generators
    npins

    (emacs-pgtk.pkgs.withPackages (epkgs:
      with epkgs;
      [
        casual
        vc-jj
        vterm
        with-editor

        # tree-sitter
        treesit-grammars.with-all-grammars
        markdown-ts-mode
        nix-ts-mode
        nushell-ts-mode
      ]
    ))
  ];
}
