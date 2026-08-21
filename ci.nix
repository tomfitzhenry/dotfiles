# https://docs.hercules-ci.com/hercules-ci-agent/evaluation/
{ src }:
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
        "claude-code"
      ];
  };
  hci-effects = (import sources.hercules-ci-effects { inherit pkgs; }).hci-effects;

  dotfiles = role: import ./config.nix { inherit role; };
in
{
  herculesCI = { primaryRepo, ... }: {
    onPush.default.outputs = _inputs: {
      checks = {
        desktop = dotfiles "desktop";
        server = dotfiles "server";
      };
    };

    onSchedule.npins-update = {
      when = {
        hour = 3;
        dayOfWeek = [ "Sun" ];
      };
      outputs = _inputs: {
        effects.npins-update = hci-effects.modularEffect {
          imports = [ hci-effects.modules.git-update ];
          git.checkout.remote.url =
            primaryRepo.remoteHttpUrl or "https://github.com/tomfitzhenry/dotfiles.git";
          git.checkout.forgeType = "github";
          git.checkout.user = "x-access-token";
          git.update.branch = "npins-update";
          git.update.baseBranch = "master";
          git.update.baseMerge.enable = true;
          git.update.baseMerge.method = "reset";
          git.update.pullRequest.title = "npins: update";
          git.update.script = ''
            npins update
            if ! git diff --quiet HEAD; then
              git add -A
              git commit -m "npins: update"
            fi
          '';
          inputs = [ pkgs.npins ];
          secretsMap.token = {
            type = "GitToken";
          };
        };
      };
    };
  };
}
