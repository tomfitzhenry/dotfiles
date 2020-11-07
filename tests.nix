# This file is a test that checks my Emacs config starts without error.
#
# This test starts a VM running NixOS with my Emacs config, starts
# Emacs, and succeeds iff Emacs starts correctly.
import (<nixpkgs> + "/nixos/tests/make-test-python.nix") ({ pkgs, ...} :
let
  emacs = pkgs.emacsWithPackages (with pkgs.emacsPackages; [
    debbugs
    eglot
    elfeed
    diff-hl
    geiser
    ibuffer-project
    magit
    nix-mode
    notmuch
    nov
    orderless
    org
    package-lint
    package-lint-flymake
    rfc-mode
    use-package
    weechat
    zenburn-theme
  ]);

  # Since the Nix VM under test doesn't have access to my dotfiles, I
  # have to somehow pass them in, in a way that Nix closes over them
  # and they end up in the Nix store.
  # I could package them up as an emacs package, but I don't know how
  # to do that, so instead I'll pass them via --directory.
  tom-emacs = pkgs.writeShellScriptBin "tom-emacs" ''
    exec ${emacs}/bin/emacs \
      --directory ${builtins.path { path = ./dotfiles/.emacs.d; name="emacs.d"; }} \
      --directory ${builtins.path { path = ./dotfiles/.emacs.d/lisp; name="emacs.d-lisp"; }} \
      "$@"
  '';
in
{
  name = "dotfiles";

  nodes = {
    workstation = {
      environment.systemPackages = [
        tom-emacs
        pkgs.git
      ];
    };
  };

  testScript =
    ''
      start_all()
      workstation.wait_for_unit("default.target")

      # Do necessary setup.
      workstation.succeed("mkdir -p ~/.emacs.d/lisp/")
      workstation.succeed("touch ~/.emacs.d/lisp/workstation.el")

      workstation.succeed(
          r"""tom-emacs --debug-init --batch --eval="(require 'init)" --kill
      """
      )
    '';
})
