# Capability suite: Desktop Fonts & Typography (CJK support, Nerd Fonts)
{ ... }:

{
  flake.nixosModules.suite-desktop-fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
  };
}
