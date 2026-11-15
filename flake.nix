{
  description = "Dorion built against OBS's CEF (H.264)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = rec {
        cef-obs = pkgs.callPackage ./cef-obs.nix { };
        dorion = pkgs.callPackage ./dorion.nix { inherit cef-obs; };
        default = dorion;
      };
    };
}
