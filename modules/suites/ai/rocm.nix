# Capability suite: ROCm AI & Compute Optimization Environment
{ ... }:

{
  flake.nixosModules.suite-ai-rocm = { ... }: {
    environment.sessionVariables = {
      AMD_COMGR_CACHE_ENABLE = "1";
      ROCFFT_KERNEL_CACHE_ENABLE = "1";
      FLASH_ATTENTION_TRITON_AMD_ENABLE = "TRUE";
    };
  };
}
