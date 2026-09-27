{
  lib,
  buildGoModule,
}:

buildGoModule {
  pname = "opencode-ntfy-notifier";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-Ac63bZlBvCrhS7b8mk7aJdApI8UGtJxnZG35L37roGY=";

  meta = {
    description = "Show xdg notifications for opencode ntfy messages and focus the matching niri workspace on click";
    homepage = "https://github.com/tomfitzhenry/dotfiles";
    license = lib.licenses.mit;
    mainProgram = "opencode-ntfy-notifier";
    platforms = lib.platforms.linux;
  };
}
