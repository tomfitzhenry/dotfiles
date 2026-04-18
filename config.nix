{ role ? "desktop" }:
let
  isDesktop = role == "desktop";
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
  file.home = {
    ".bash_profile".source = ./dotfiles/.bash_profile;
    ".bashrc".source = ./dotfiles/.bashrc;
    ".gitconfig".source = ./dotfiles/.gitconfig;
    ".config/emacs/init.el".source = ./dotfiles/.config/emacs/init.el;
    ".config/nix/nix.conf".source = ./dotfiles/.config/nix/nix.conf;
    ".mg".source = ./dotfiles/.mg;
  } // (if isDesktop then {
    ".config/sway".source = ./dotfiles/.config/sway;
  } else {});

  packages = with pkgs; [
    aria2
    gh
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

    curl
    dig
    fzf
    jq
    ncdu
    ripgrep
    tree

    ssh-tpm-agent

    # Passwords
    passage
    age-plugin-yubikey
    yubikey-manager

    # LSP
    bash-language-server
    go
    gopls
    nixd

    # Networking
    autossh
    lftp
    mptcpd

    # LLM
    claude-code
    gemini-cli
    ollama
    opencode
    pi-coding-agent
    python3

    # Nix
    nixfmt-tree
    nixos-generators
    npins
    nix-init
    nixpkgs-review

    (emacs-pgtk.pkgs.withPackages (
      epkgs: with epkgs; [
        casual
        pi-coding-agent
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

  ] ++ pkgs.lib.optionals isDesktop [

    niri
    noctalia-shell

    # Desktop applications
    brave
    signal-desktop
    telegram-desktop
    foliate
    showtime

    # WM
    ghostty
    font-awesome
    wl-clipboard
    xwayland-run
  ];

  # https://github.com/Foxboron/ssh-tpm-agent/blob/master/contrib/services/user/ssh-tpm-agent.service
  systemd.services.ssh-tpm-agent = {
    unitConfig = {
      ConditionEnvironment = "!SSH_AGENT_PID";
      Description = "ssh-tpm-agent service";
    };
    requires = [ "ssh-tpm-agent.socket" ];
    serviceConfig = {
      ExecStart = pkgs.lib.getExe pkgs.ssh-tpm-agent;
      PassEnvironment = "SSH_AGENT_PID";
      Environment = [
        "SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock"
      ];
      SuccessExitStatus = 2;
    };
  };

  # https://github.com/Foxboron/ssh-tpm-agent/blob/master/contrib/services/user/ssh-tpm-agent.socket
  systemd.sockets.ssh-tpm-agent = {
    unitConfig = {
      Description = "SSH TPM agent socket";
    };
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/ssh-tpm-agent.sock";
      SocketMode = "0600";
      Service = "ssh-tpm-agent.service";
    };
  };
}
