{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "opencode-ntfy";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "tomfitzhenry";
    repo = "opencode-ntfy.sh";
    rev = "2941e5ce15b44a30dd25e0938a0fc8d33cec2775";
    hash = "sha256-mmaPSSQNsSBHgTkoyah15bHHq83AWZn+eH5Kb6bhbYg=";
  };

  # buildNpmPackage runs `npm ci`; the fork ships only bun/yarn locks.
  postPatch = ''
    cp ${./opencode-ntfy/package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-z570/xmdVouXUY6jPoz9YXntOAors8iKgC9zsiiZJOQ=";
  npmBuildScript = "build";

  # Stable path for the nix-maid symlink.
  postInstall = ''
    ln -s "$out/lib/node_modules/opencode-ntfy.sh" "$out/lib/opencode-ntfy"
  '';

  meta = {
    description = "OpenCode plugin that sends push notifications via ntfy.sh";
    homepage = "https://github.com/tomfitzhenry/opencode-ntfy.sh";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
