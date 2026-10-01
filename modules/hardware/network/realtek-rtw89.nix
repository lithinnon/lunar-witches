# Hardware trait: Realtek rtw89 PCIe/USB wireless chipset quirks
{ ... }:

{
  flake.nixosModules.hw-network-realtek-rtw89 = { ... }: {
    boot.extraModprobeConfig = ''
      options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y disable_clkreq=y
      options rtw89_core disable_ps_mode=y
    '';
  };
}
