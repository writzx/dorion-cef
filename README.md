# dorion-cef

[Dorion](https://github.com/SpikeHD/Dorion) 7 built against OBS's CEF build, which includes H.264. The Spotify CEF builds do not, so Discord streams do not play.

```nix
inputs.dorion-cef.url = "github:writzx/dorion-cef";

home.packages = [ inputs.dorion-cef.packages.x86_64-linux.dorion ];
```
