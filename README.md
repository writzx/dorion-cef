# dorion-cef

[Dorion](https://github.com/SpikeHD/Dorion) 7 built against OBS's CEF build, which includes H.264. The Spotify CEF builds do not, so Discord streams do not play.

```nix
inputs.dorion-cef.url = "github:writzx/dorion-cef";

home.packages = [ inputs.dorion-cef.packages.x86_64-linux.dorion ];

nix.settings = {
  extra-substituters = [ "https://dorion-cef.cachix.org" ];
  extra-trusted-public-keys = [ "dorion-cef.cachix.org-1:EEPuBHLUnx3eYaBFnrXtYaEUiol96P5/8ftTgSksd80=" ];
};
```

Binaries are built by GitHub Actions and served from the cache. Don't make `nixpkgs` follow yours, or the cache won't match. The nixpkgs pin is updated weekly.
