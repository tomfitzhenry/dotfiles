{ role ? "desktop" }:
let
  isDesktop = role == "desktop";
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  multiverse = import sources.nixpkgs-multiverse { };
  nix-maid = import sources.nix-maid;
in
nix-maid pkgs {
  imports = [
    ./modules/bashrc.nix
    ./modules/radicle.nix
  ];

  file.home = {
    ".bash_profile".source = ./dotfiles/.bash_profile;
    ".config/emacs/init.el".source = ./dotfiles/.config/emacs/init.el;
    ".config/git/config".source = ./dotfiles/.config/git/config;
    ".config/jj/config.toml".source = ./dotfiles/.config/jj/config.toml;
    ".config/nix/nix.conf".source = ./dotfiles/.config/nix/nix.conf;
    ".config/opencode/AGENTS.md".source = ./dotfiles/.config/opencode/AGENTS.md;
    ".mg".source = ./dotfiles/.mg;
    ".pi/agent/AGENTS.md".source = ./dotfiles/.config/opencode/AGENTS.md;
  } // (if isDesktop then {
    ".config/sway".source = ./dotfiles/.config/sway;
  } else {});

  home.sessionVariables = {
    EDITOR = "mg";
    # Claude Code's TUI enables terminal mouse tracking but doesn't disable it on
    # ungraceful SSH disconnect (laptop sleep + autossh reconnect), leaving the
    # terminal reporting every mouse move as SGR sequences that the fresh login
    # shell echoes as text spam. Disable mouse capture at the app level:
    # https://github.com/anthropics/claude-code/issues/72648
    CLAUDE_CODE_DISABLE_MOUSE = "1";
  };

  home.bashrc.extraConfig = ''
    shopt -s histappend
    HISTSIZE=2000
    HISTFILESIZE=20000

    if command -v fzf-share >/dev/null; then
      source "$(fzf-share)/key-bindings.bash"
    fi

    SSH_AUTH_SOCK="$(ssh-tpm-agent --print-socket)"
    export SSH_AUTH_SOCK
  '';

  packages = with pkgs; [
    wrangler
    aria2
    forgejo-cli
    gh
    git
    git-lfs
    jujutsu
    dtach
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
    # noctalia-shell updates break my session, so let's control those.
    (multiverse.fast.version "noctalia-shell" "4.7.7")
    
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

}
