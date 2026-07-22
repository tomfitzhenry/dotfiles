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
    wrangler
    aria2
    forgejo-cli
    gh
    git
    git-lfs
    jujutsu
    shpool
    gittuf
    lefthook
    mg
    nodejs
    nushell
    openssh # since SteamOS's openssh has no libfido2.so
    pomerium-cli
    p7zip
    restic
    wormhole-william
    xxd
    yt-dlp

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
    typescript-language-server

    # Networking
    autossh
    lftp
    mptcpd
    (writeShellApplication {
      name = "rssh";
      runtimeInputs = [ mptcpd autossh openssh ];
      text = ''
        mptcpize run autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" "$@"
      '';
    })

    # Cloud
    oci-cli
    (pulumi.withPackages (pu: [ pu.pulumi-nodejs ]))

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

    # Rust
    rustup
    gcc

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
    opensc

    # Desktop applications
    brave
    evince
    signal-desktop
    telegram-desktop
    tor-browser
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

  # https://github.com/shell-pool/shpool/blob/master/systemd/shpool.service
  systemd.services.shpool = {
    unitConfig = {
      Description = "Shpool - Shell Session Pool";
    };
    requires = [ "shpool.socket" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.lib.getExe pkgs.shpool} daemon";
      KillMode = "mixed";
      TimeoutStopSec = "2s";
      SendSIGHUP = "yes";
    };
    wantedBy = [ "default.target" ];
  };

  # https://github.com/shell-pool/shpool/blob/master/systemd/shpool.socket
  systemd.sockets.shpool = {
    unitConfig = {
      Description = "Shpool Shell Session Pooler";
    };
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/shpool/shpool.socket";
      SocketMode = "0600";
      Service = "shpool.service";
    };
  };
}
