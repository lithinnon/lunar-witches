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

    fonts.fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif"
          "Noto Serif CJK JP"
          "Noto Serif CJK SC"
          "Noto Serif CJK KR"
        ];
        sansSerif = [
          "Noto Sans"
          "Noto Sans CJK JP"
          "Noto Sans CJK SC"
          "Noto Sans CJK KR"
        ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono CJK JP"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
