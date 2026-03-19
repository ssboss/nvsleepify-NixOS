# Nvsleepify-NixOS

This flake ports over Nvsleepify over to NixOS for anyone running NixOS on an Asus Zephyrus laptop with NVIDIA dedicated graphics. **Note:** This is NOT the official project, and any issues, feature requests, or praise regarding the official project should be given to the creator here: [https://github.com/JuanDelPueblo/nvsleepify](https://github.com/JuanDelPueblo/nvsleepify). 

## Features
- Builds and installs binaries of nvsleepify for dGPU management in NixOS
- Adds easy integration into flake and non-flake setups

## Installation
Simply import it in your flake and add it to your modules: 

```nix
inputs.nvsleepify.url = "https://github.com/ssboss/nvsleepify-NixOS.git"

...

modules = [
    # other modules you have
    nvsleepify.nixosModules.nvsleepify
]
```
Thenm you can enable it in your setup with this:
```
services.nvsleepify.enable = true;
```

For non flake systems, simply import the overlay into your file, and then you can enable just like above.